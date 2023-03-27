# SwiftUI Map App - Toy Project

![MapApp](https://user-images.githubusercontent.com/114594496/227917806-46cd990a-ccc1-4bff-b1fe-c07289bcdd36.gif)

## 앱 설명

- 아이폰 내부 지도 api를 이용하여 지도를 구현 해봤습니다.

## 앱 기능

- 유저 위치 권한 허락 설정
- 검색 후 검색 리스트 누르면 위치 이동
- 현재 내 위치 표시 버튼
- 위성 , 그림 지도 전환 버튼
- 검색 한 곳 마커 찍기

# Model

- Identifiable : 객체 안에 id를 지정해주어 사용할 때 정확히 불러올 수 있게해줌
- CLPlacemark : 종종 장소의 이름, 주소 및 기타 관련 정보를 포함하는 지리적 좌표를 가져옴
- Mapkit : Apple Map을 사용 지도나 위성이미지, 좌표등 지도를 사용할 수 있음.

```swift
import SwiftUI
import MapKit

struct Place: Identifiable {
    
    var id = UUID().uuidString
    var placemark: CLPlacemark
  
}
```


# HomeView

## 문법

- CoreLocation : 장치의 지리적위치와 방향을 확인, 고도, 방향등 위치를 결정하는 서비스를 제공
    - 사용자의 현재 위치에서의 크고 작은 변경을 정확하게 추적합니다
- MapViewModel : ViewModel에서 만든 지도관리
- environmentObject : 뷰간의 데이터공유
- ignoresSafeArea : 화면전체의 공간을 다룸
- colorScheme : 색의 테마
- isEmpty : 문자열이 비어있는지 확인
- onTapGesture : 터치 하였을때 실행
- Divider : 공간 분리
- onAppear : 나타내기
- requestWhenInUseAuthorization : 위치권한설정
- isPresented : 뷰가 현재 표시되는지
- dismissButton : 허락버튼
- onChange : 이벤트 내용 변경감지

```swift
import SwiftUI
import CoreLocation

struct Home: View {
    
    @StateObject var mapData = MapViewModoel()
    // 지역 관리자
    @State var locationManager = CLLocationManager()
    
    
    var body: some View {
        ZStack{
            // mapview
            // using it as environment object so that it can be used ints subViews
            MapView()
                .environmentObject(mapData)
                .ignoresSafeArea(.all,edges: .all)
            
            
            VStack{
                
                VStack(spacing: 0) {
                    HStack{
                        
                        Image(systemName:  "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search", text: $mapData.searchText)
                            .colorScheme(.light)
                    }
                    .padding(.vertical,10)
                    .padding(.horizontal)
                    .background(Color.white)
                    
                    // Displaying Results
                    
                    if !mapData.places.isEmpty && mapData.searchText != ""{
                        
                        ScrollView{
                            VStack(spacing: 15){
                                
                                ForEach(mapData.places){place in
                                    
                                    Text(place.placemark.name ?? "")
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity,alignment: .leading)
                                        .padding(.leading)
                                        .onTapGesture {
                                            mapData.selectPlace(place: place)
                                        }
                                    
                                    Divider()
                                    
                                }
                            }
                            .padding(.top)
                        }
                        .background(Color.white)
                        
                    }
                    
                }
                .padding()
                
                Spacer()
                
                VStack{
                    
                    Button(action: mapData.focusLocation, label: {
                        
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding(10)
                            .background(Color.primary)
                            .clipShape(Circle())
                    })
                    
                    Button(action: mapData.updateMapType, label: {
                        
                        Image(systemName: mapData.mapType ==
                            .standard ? "network" : "map")
                            .font(.title2)
                            .padding(10)
                            .background(Color.primary)
                            .clipShape(Circle())
                    })
                    
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .onAppear(perform: {
            
            // 설정 위임
            locationManager.delegate = mapData
            locationManager.requestWhenInUseAuthorization()
        })
        .alert(isPresented: $mapData.permissionDenied, content: {

            Alert(title: Text("허용을 안하셨습니다."),
                message: Text("앱설정내에서 허가를 해주시길 바랍니다."),
                dismissButton: .default(Text("설정 가기"),
                action:  {

                // 사용자를 설정환경으로 보냄
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))
        })
        .onChange(of: mapData.searchText, perform: { value in
            
            // searching place
            
            // you can use your own delay time to avoid Continous Search Request
            let delay = 0.3
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay){
                
                if value == mapData.searchText{
                    
                    // search
                    self.mapData.searchQuery()
                }
            }
            
        })
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
```

# MapView

## 문법

- @EnvironmentObject : 필요한 곳 어디에서나 데이터를 공유
- Coordinator : 앱 전반에 있어서 화면전환를 담당
- showsUserlocation : 유저의 위치를 추적
- delegate : 일을 위임해준다..? 이해잘못함
- MKAnnotationView : 주석을 시각화
- reuseIdentifier : 주석 유형을 명확하게 정의하는 경우(주석 보기와 함께 사용할 수 있는 주석) 각 유형에 대해 서로 다른 재사용 식별자를 지정하여 주석 유형을 구분할 수 있습니다.

```swift
import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    
    @EnvironmentObject var mapData: MapViewModoel // 필요한 곳 어디에서나 데이터를 공유
    
    func makeCoordinator() -> Coordinator {
        return MapView.Coordinator()
    }
    
    func makeUIView(context: Context) -> MKMapView {
        
        let view = mapData.mapView
        
        view.showsUserLocation = true
        view.delegate = context.coordinator
         
        return view
        
    }
    func updateUIView(_ uiView: MKMapView, context: Context) {
        
    }
    class Coordinator: NSObject,MKMapViewDelegate{
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            
            // Custom Pins
            
            // Excluding user blue circle
            
            if annotation.isKind(of: MKUserLocation.self){return nil}
            else{
                let pinAnnotation = MKPinAnnotationView(annotation: annotation,
                    reuseIdentifier: "PIN_VIEW")
                pinAnnotation.tintColor = .red
                pinAnnotation.animatesDrop = true
                pinAnnotation.canShowCallout = true
                
                return pinAnnotation
            }
        }
        
    }
}
```


# ViewModel

## 문법

- MKMapView : 지도를 불러오는 함수
- Published : 속성을 게시하는 유형
- MKCoordinateRegion! : 특정 위도와 경도를 중심으로 한 직사각형 영역
- MKMapType : 표시할 맵의 유형 ( 위성모습, 지도모습)
- [Place] : 장소찾기
- updateMapType() : 맵의 유형 고르기
- mapType = .standard / .hybird  : 맵 형태를 기본, 하이브리드로
- focusLocation : 지역 조정
- guard let _ = region else{return}
    - guard 뒤에 따라붙는 코드의 실행 결과가 true일때 코드가 계속 실행
    - guard 뒤 따라오는 Bool 값이 false라면 else의 블록 내부 코드를 실행
    - 코드 블록 종료시 return, break, continue, throw 등 제어문 전환 명령
- setRegion(region, animated: true) :
    - 보이는 영역을 변경하고 선택적으로 변경사항을 애니메이션화
    - region 지도보기에 표시할 새 영역
    - 새 영역으로의 전환을 애니메이션으로 만들 것인지 또는 맵이 지정된 영역의 중심에 즉시 배치되도록 할 것인지 지정
- setVisibleMapRect(mapView.visibleMapRect, animated: **true**) :
    - 가장자리 주위에 추가 공간을 지정 지도에서 현재 보이는 부분을 변경
    - visibleMapRect: 현재 지도 보기에서 표시되는 영역
- MKLocalSearch.Request() : 지도 기반 검색을 시작하고 결과를 처리하기 위한 유틸리티 개체.
- naturalLanguageQuery : 원하는 검색 항목을 포함하는 문자열
- MKLocalSearch(request: request).start { (response, _) **in** : map 검색창을 가져옴
- MKMapItem :
    - 지도 앱으로 지도 관련 데이터를 공유합니다.
    - 지도 앱에서 발생하는 길 안내 요청을 처리합니다.
- compactMap : 1차원 배열에서 nil을 제거하고 옵셔널 바인딩을 하고 싶을때 사용
    - 옵셔널 바인딩 : 옵셔널 값은 랩에 쌓여 있어서, 사용하기 위해서는 unwrapping하는 과정이 필요
- coordinate : 주석의 좌표점
- MKPointAnnotation : 맵의 지점을 문자열로 가져오는 데이터
- [place.placemark.name](http://place.placemark.name/) ?? "No Name" : 물음표 두개는 Nil-coalescing operator 어떤 값이 nil일수도 있는 상황일때 nil 대신 다른 디폴트 값을 주고싶을때 사용
- removeAnnotations : 지정된 객체를 지도에서 제거
- addAnnotation : 지정된 객체를 지도에 추가
- MKCoordinateRegion : 중앙 / 위도측정 / 종도측정 /지정된 좌표 및 거리 값으로 새 좌표 영역을 작성한다.
- setRegion :
    - 보이는 영역을 변경하고 선택적으로 변경사항을 애니메이션화
    - region 지도보기에 표시할 새 영역
    - 새 영역으로의 전환을 애니메이션으로 만들 것인지 또는 맵이 지정된 영역의 중심에 즉시 배치되도록 할 것인지 지정
- setVisibleMapRect(mapView.visibleMapRect, animated: **true**) :
    - 가장자리 주위에 추가 공간을 지정 지도에서 현재 보이는 부분을 변경
    - visibleMapRect: 현재 지도 보기에서 표시되는 영역
- CLLocationManager : 앱으로 위치관련이벤트전달을 시작하고 중지하는데 사용
- denied : 알람
- notDetermined : 요청
- authorizedWhenInUse : 허가 받은 상황
- requestLocation() : 사용자의 현재위치를 일회성으로 전송요청
- latitudinalMeters : 중앙에서 북, 남축을 따라 지정된 영역을 측정
- longisticalMeters : 중앙에서 동서축을 따라 지정된 영역을 측정

```swift

import SwiftUI
import MapKit
import CoreLocation

// 모든 지도의 데이터를 가져온다

class MapViewModoel: NSObject,ObservableObject,CLLocationManagerDelegate{
    
    @Published var mapView = MKMapView() // Published = 속성을 게시하는 유형 , 값을 변화or업데이트 할 수 있음 MKMapView = 지도를 불러오는 함수
    

    // 지역
    @Published var region : MKCoordinateRegion! // 특정 위도와 경도를 중심으로 한 직사각형 영역
    // 기본 위치 설정
    
    // 알람
    @Published var permissionDenied  = false // 허가를 거부한다. 사용자 위치 허락 거부
    
    
    // Map Type..
    @Published var mapType : MKMapType = .standard // 표시할 맵의 유형
    
    // SearchText
    @Published var searchText = "" // 문자검색
    
    // searched place
    @Published var places: [Place] = [] // 장소 찾기
    
    
    // Updating Map Type..
    
    func updateMapType(){ // 맵의 유형 고르기
        
        if mapType == .standard{ // 맵 형태를 스탠다드일때
            mapType = .hybrid// 맵 형태를 하이브리드
            mapView.mapType = mapType
        }
        else{
            mapType = .standard // 맵 형태를 스탠다드로
            mapView.mapType = mapType
        }
    }
    
    // Focus Location
    
    func focusLocation(){ // 지역을 집중시키기.
        
        guard let _ = region else{return}   //guard 뒤에 따라붙는 코드의 실행 결과가 true일 때 코드가 계속 실행
                                            //guard 뒤 따라오는 Bool 값이 false라면 else의 블록 내부 코드를 실행
                                            //코드 블록 종료시 return, break, continue, throw 등 제어문 전환 명령
            
            mapView.setRegion(region, animated: true)   //setRegion 보이는 영역을 변경하고 선택적으로 변경사항을 애니메이션화
                                                        //region 지도보기에 표시할 새 영역
                                                        //새 영역으로의 전환을 애니메이션으로 만들 것인지 또는 맵이 지정된 영역의 중심에 즉시 배치되도록 할 것인지 지정
            mapView.setVisibleMapRect(mapView.visibleMapRect, animated: true)
                        //가장자리 주위에 추가 공간을 지정 지도에서 현재 보이는 부분을 변경
                        //visibleMapRect: 현재 지도 보기에서 표시되는 영역
    }
    
    // search place
    
    func searchQuery(){
        
        places.removeAll() // 제거할 상태 ( ) 를 적어준다. 그자리에서 객체를 제거 불필요한 복사 x
        
        let request = MKLocalSearch.Request() //  지도 기반 검색을 시작하고 결과를 처리하기 위한 유틸리티 개체.
        request.naturalLanguageQuery = searchText //naturalLanguageQuery : 원하는 검색 항목을 포함하는 문자열
        
        // fetch
        MKLocalSearch(request: request).start { (response, _) in // map 검색창을 가져옴
            
            guard let result = response else{return} // 검색텍스트창에서 사용자가 원하는부분을 선택하여 검색완료를 하면 그장소를가져옴
            
            self.places = result.mapItems.compactMap({ (item) -> Place? in
                return Place(placemark: item.placemark)
            })
        }
    }
    
    // Pick Search Result..
    
    func selectPlace(place: Place){
        
        // Showing Pin on Map
        
        searchText = ""
        
        guard let coordinate = place.placemark.location?.coordinate else{return} // coordinate: 주석의 좌표점
        
        let pointAnnotation = MKPointAnnotation() // MKPointAnnotation : 맵의 지점을 문자열로 가져오는 데이터
        pointAnnotation.coordinate = coordinate
        pointAnnotation.title = place.placemark.name ?? "No Name" // 물음표 두개는 Nil-coalescing operator 어떤 값이 nil일수도 있는 상황일때 nil 대신 다른 디폴트 값을 주고싶을때 사용
        
        // Removing All Old ones..
        mapView.removeAnnotations(mapView.annotations) // 지정된 객체를 지도에서 제거
        
        mapView.addAnnotation(pointAnnotation) // 지정된 객체를 지도에 추가
        
        // Moving Map To that location
        
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000) // 중앙 / 위도측정 / 종도측정 /지정된 좌표 및 거리 값으로 새 좌표 영역을 작성한다.
        
        mapView.setRegion(coordinateRegion, animated: true) //setRegion 보이는 영역을 변경하고 선택적으로 변경사항을                                                        애니메이션화
                                                            //region 지도보기에 표시할 새 영역
                                                            //새 영역으로의 전환을 애니메이션으로 만들 것인지 또는 맵이 지정된 영역의 중심에 즉시 배치되도록 할 것인지 지정
        mapView.setVisibleMapRect(mapView.visibleMapRect, animated: true)
                            //가장자리 주위에 추가 공간을 지정 지도에서 현재 보이는 부분을 변경
                            //visibleMapRect: 현재 지도 보기에서 표시되는 영역
    }
    
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
                                //CLLocationManager: 앱으로 위치관련이벤트전달을 시작하고 중지하는데 사용
            
        // 권한 확인
        
        switch manager.authorizationStatus {
        case .denied:
            // 알람
            permissionDenied.toggle()
        case .notDetermined:
            // 요청
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // 허가 받은 상황
            manager.requestLocation() // 사용자의 현재위치를 일회성으로 전송요청
        default:
            ()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        // 에러
        print(error.localizedDescription) // 오류에 대한 지역화된 설명을 제공
    }
    
    // 사용자 지역 가져오기
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        guard let location = locations.last else{return}

        self.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)

        // 지도 업데이트
        self.mapView.setRegion(self.region, animated: true)

        // 부드러운 애니메이션
        self.mapView.setVisibleMapRect(self.mapView.visibleMapRect, animated: true)
    }
    
    
}
```


---

