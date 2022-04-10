//
//  Home.swift
//  IphonMapApp (iOS)
//
//  Created by 하명관 on 2022/04/09.
//

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
       //  권한 거부 경고
//        .alert(isPresented: $mapData.permissionDenied, content: {
//
//            Alert(title: Text("허용을 안하셨습니다."),
//                message: Text("앱설정내에서 허가를 해주시길 바랍니다."),
//                dismissButton: .default(Text("설정 가기"),
//                action:  {
//
//                // 사용자를 설정환경으로 보냄
//                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
//            }))
//        })
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
