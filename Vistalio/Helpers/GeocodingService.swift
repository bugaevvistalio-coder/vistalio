//
//  GeocodingService.swift
//  Vistalio
//
//  Created by Julia Konkova on 07.11.2026.
//

import Foundation
import CoreLocation
import MapKit

final class GeocodingService {
    
    static let shared = GeocodingService()
    
    private let appleGeocoder = CLGeocoder()
    
    private init() {}
    
    func fetchGeoapifyAddress(from coordinate: CLLocationCoordinate2D, completion: @escaping (String?, CLLocationCoordinate2D) -> Void) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.geoapify.com"
        components.path = "/v1/geocode/reverse" // Эндпоинт обратного геокодинга Geoapify
        
        components.queryItems = [
            URLQueryItem(name: "lat", value: "\(coordinate.latitude)"),
            URLQueryItem(name: "lon", value: "\(coordinate.longitude)"),
            URLQueryItem(name: "lang", value: "ru"),
            URLQueryItem(name: "apiKey", value: geoapifyApiKey)
        ]
        
        guard let url = components.url else {
            self.fetchAppleAddress(from: coordinate, completion: completion)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 3.5
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if error != nil {
                self?.fetchAppleAddress(from: coordinate, completion: completion)
                return
            }
            
            guard let data = data else {
                self?.fetchAppleAddress(from: coordinate, completion: completion)
                return
            }
            
            do {
                // Разбираем структуру GeoJSON от Geoapify
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let features = json["features"] as? [[String: Any]],
                   let firstFeature = features.first,
                   let properties = firstFeature["properties"] as? [String: Any] {
                    
                    let street = properties["street"] as? String ?? ""
                    let house = properties["housenumber"] as? String ?? ""
                    let city = properties["city"] as? String ?? ""
                    
                    if !street.isEmpty && !house.isEmpty {
                        completion("\(city), \(street), \(house)", coordinate)
                    } else if !street.isEmpty {
                        completion("\(city), \(street)", coordinate)
                    } else {
                        let formattedAddress = properties["formatted"] as? String ?? ""
                        completion(self?.formatAddress(formattedAddress), coordinate)
                    }
                } else {
                    self?.fetchAppleAddress(from: coordinate, completion: completion)
                }
            } catch {
                self?.fetchAppleAddress(from: coordinate, completion: completion)
            }
        }.resume()
    }
    
    func fetchAppleAddress(from coordinate: CLLocationCoordinate2D, completion: @escaping (String?, CLLocationCoordinate2D) -> Void) {
        print("⚠️ Сбой Geoapify. Переключение на нативный Apple CLGeocoder...")
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        appleGeocoder.reverseGeocodeLocation(location) { placemarks, _ in
            if let placemark = placemarks?.first {
                let street = placemark.thoroughfare ?? ""
                let house = placemark.subThoroughfare ?? ""
                let city = placemark.locality ?? ""
                
                if !street.isEmpty && !house.isEmpty {
                    completion("\(city), \(street), \(house)", coordinate)
                } else {
                    completion(placemark.name ?? city, coordinate)
                }
            } else {
                completion(nil, coordinate)
            }
        }
    }
    
    private func formatAddress(_ rawAddress: String) -> String {
        let components = rawAddress.components(separatedBy: ", ")
        let maxCount = min(components.count, 4)
        return components.prefix(maxCount).joined(separator: ", ")
    }
    
    func autocompleteGeoapifySearch(text: String, biasCoordinate: CLLocationCoordinate2D?, completion: @escaping ([AddressPrediction], String) -> Void) {
        guard !text.isEmpty else {
            completion([], text)
            return
        }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.geoapify.com"
        components.path = "/v1/geocode/autocomplete"
        
        var queryItems = [
            URLQueryItem(name: "text", value: text),
            URLQueryItem(name: "lang", value: "ru"),
            URLQueryItem(name: "limit", value: "7"),
            URLQueryItem(name: "type", value: "amenity"), 
            URLQueryItem(name: "apiKey", value: geoapifyApiKey)
        ]
        
        if let bias = biasCoordinate {
            queryItems.append(URLQueryItem(name: "bias", value: "proximity:\(bias.longitude),\(bias.latitude)"))
            
            let radiusInMeters = 50000
            queryItems.append(URLQueryItem(name: "filter", value: "circle:\(bias.longitude),\(bias.latitude),\(radiusInMeters)"))
        }
        
        components.queryItems = queryItems
        guard let url = components.url else {
            completion([], text)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion([], text)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let features = json["features"] as? [[String: Any]] {
                    
                    var results: [AddressPrediction] = []
                    
                    for feature in features {
                        if let properties = feature["properties"] as? [String: Any],
                           let lon = properties["lon"] as? Double,
                           let lat = properties["lat"] as? Double {
                            
                            let street = properties["street"] as? String ?? ""
                            let house = properties["housenumber"] as? String ?? ""
                            let city = properties["city"] as? String ?? (properties["county"] as? String ?? "")
                            let country = properties["country"] as? String ?? ""
                            
                            let address = !street.isEmpty ? "\(street)\(!house.isEmpty ? ", " + house : "")" : (properties["name"] as? String ?? city)
                            let countryCity = !city.isEmpty && city != address ? "\(city), \(country)" : country
                            
                            let prediction = AddressPrediction(
                                address: address,
                                countryCity: countryCity,
                                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            )
                            results.append(prediction)
                        }
                    }
                    completion(results, text)
                } else {
                    completion([], text)
                }
            } catch {
                completion([], text)
            }
        }.resume()
    }
    
    func autocompleteAppleSearch(text: String, biasCoordinate: CLLocationCoordinate2D?, completion: @escaping ([AddressPrediction], String) -> Void) {
        guard !text.isEmpty else {
            completion([], text)
            return
        }
        
        // Настраиваем географический фокус, чтобы в приоритете вылезали дома вашего города
        let region: CLRegion?
        if let center = biasCoordinate {
            // Создаем круглый регион радиусом 50 км вокруг центра экрана
            region = CLCircularRegion(center: center, radius: 50000, identifier: "searchRegion")
        } else {
            region = nil
        }
        
        // Запускаем нативный прямой геокодинг Apple
        appleGeocoder.geocodeAddressString(text, in: region) { placemarks, error in
            if let error = error {
                print("Ошибка поиска Apple: \(error.localizedDescription)")
                completion([], text)
                return
            }
            
            guard let placemarks = placemarks else {
                completion([], text)
                return
            }
            
            var results: [AddressPrediction] = []
            
            // Apple возвращает максимум 5-10 наиболее подходящих объектов
            for placemark in placemarks {
                guard let location = placemark.location else { continue }
                
                let street = placemark.thoroughfare ?? ""
                let house = placemark.subThoroughfare ?? ""
                let city = placemark.locality ?? ""
                let country = placemark.country ?? ""
                
                // Собираем строки дляsubtitle-ячеек в вашей UITableView
                let main = !street.isEmpty ? "\(street)\(!house.isEmpty ? ", " + house : "")" : (placemark.name ?? city)
                let sub = !city.isEmpty && city != main ? "\(city), \(country)" : country
                
                let prediction = AddressPrediction(
                    address: main,
                    countryCity: sub,
                    coordinate: location.coordinate
                )
                results.append(prediction)
            }
            
            completion(results, text)
        }
    }
    
    func autocompleteMapboxSearch(text: String, biasCoordinate: CLLocationCoordinate2D?, completion: @escaping ([AddressPrediction], String) -> Void) {
        guard !text.isEmpty else { completion([], text); return }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.mapbox.com"
        
        components.path = "/search/searchbox/v1/suggest"
                
        // Создаем уникальную сессию для пользователя (требование Mapbox для связки ввода)
        let sessionToken = "session_12345"
        
        var queryItems = [
            URLQueryItem(name: "q", value: text.trim()),
            URLQueryItem(name: "access_token", value: mapboxToken),
            URLQueryItem(name: "session_token", value: sessionToken),
//            URLQueryItem(name: "types", value: " address,street,place"), // Предлагаем только конечные адреса строений
            URLQueryItem(name: "limit", value: "8"),
            URLQueryItem(name: "language", value: "ru")
        ]
        
        // Жесткая привязка к текущему городу на карте для идеального угадывания локальных домов
        if let bias = biasCoordinate {
            queryItems.append(URLQueryItem(name: "proximity", value: "\(bias.longitude),\(bias.latitude)"))
        }
        
        components.queryItems = queryItems
        guard let url = components.url else { completion([], text); return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 2.5
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { completion([], text); return }
            print("Mapbox response \(response)")
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let suggestions = json["suggestions"] as? [[String: Any]] {
                    
                    var results: [AddressPrediction] = []
                    
                    for item in suggestions {
                        // Поисковые подсказки Search Box API возвращают уже разделенный готовый адрес!
                        let name = item["name"] as? String ?? "" // Например: "Коммунистический проспект, 40"
                        let placeFormatted = item["place_formatted"] as? String ?? "" // Например: "Северск, Томская область, Россия"
                        
                        // Извлекаем встроенные координаты подсказки (у Search Box они лежат прямо в корне элемента)
                        // Внимание: некоторые подсказки типов могут не иметь координат, пока по ним не тапнешь (метод retrieve),
                        // но для типа "address" Mapbox обычно отдает их сразу в блоке "coordinates"
                        var lat: Double = 0.0
                        var lon: Double = 0.0
                        
                        if let externalIds = item["external_ids"] as? [String: Any],
                           let safetylocation = externalIds["coordinates"] as? [String: Any],
                           let latitude = safetylocation["latitude"] as? Double,
                           let longitude = safetylocation["longitude"] as? Double {
                            lat = latitude
                            lon = longitude
                        } else if let fallbackCoordinates = item["coordinates"] as? [String: Any],
                                  let latitude = fallbackCoordinates["latitude"] as? Double,
                                  let longitude = fallbackCoordinates["longitude"] as? Double {
                            lat = latitude
                            lon = longitude
                        }
                        
                        let prediction = AddressPrediction(
                            address: name,
                            countryCity: placeFormatted,
                            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        )
                        results.append(prediction)
                    }
                    completion(results, text)
                } else {
                    completion([], text)
                }
            } catch {
                completion([], text)
            }
        }.resume()
    }
    
    func appleLocalSearch(text: String, biasCoordinate: CLLocationCoordinate2D?, completion: @escaping ([AddressPrediction], String) -> Void) {
        
        let trimmedText = text.trim()
        guard !trimmedText.isEmpty else { completion([], text); return }
        
        // Настраиваем поисковый запрос
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmedText
        request.resultTypes = [.pointOfInterest, .address] // Ищем одновременно и дома, и организации!
        
        // Привязываем фокус поиска к текущему экрану карты, чтобы первыми шли ближайшие места
        if let bias = biasCoordinate {
            // Создаем регион радиусом примерно 30 км вокруг центра карты
            let region = MKCoordinateRegion(
                center: bias,
                latitudinalMeters: 30000,
                longitudinalMeters: 30000
            )
            request.region = region
        }
        
        // Запускаем нативный поисковый движок
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                print("Ошибка поиска MKLocalSearch: \(error?.localizedDescription ?? "unknown")")
                completion([], text)
                return
            }
            
            var results: [AddressPrediction] = []
            
            // Пробегаемся по найденным объектам (Apple автоматически очищает их от дублей)
            for item in response.mapItems {
                let placemark = item.placemark
                let coordinate = placemark.coordinate
                
                // Извлекаем название (для организации это будет "Сбербанк", для дома — "ул. Ленина, 10")
                let name = item.name ?? ""
                
                // Собираем вторую строчку (Город, Страна)
                let city = placemark.locality ?? ""
                let country = placemark.country ?? ""
                
                let mainAddress: String
                let subAddress: String
                
                if item.isCurrentLocation { continue }
                
                // Если это организация, красиво форматируем подзаголовок ячейки
                if item.pointOfInterestCategory != nil {
                    mainAddress = name // "Сбербанк"
                    let street = placemark.thoroughfare ?? ""
                    let subThoroughfare = placemark.subThoroughfare ?? ""
                    let road = !street.isEmpty ? "\(street)\(!subThoroughfare.isEmpty ? ", " + subThoroughfare : "")" : ""
                    subAddress = !road.isEmpty ? "\(road), \(city)" : city
                } else {
                    // If it's a regular building/street address
                    mainAddress = name // "улица Вершинина, 40"
                    subAddress = !city.isEmpty ? "\(city), \(country)" : country
                }
                
                // Сохраняем координаты сразу в строку ID, чтобы летать по карте мгновенно
                let suggestion = AddressPrediction(
                    address: mainAddress,
                    countryCity: subAddress,
                    coordinate: coordinate
                )
                results.append(suggestion)
            }
            
            if let bias = biasCoordinate {
                results.sort {
                    let location1 = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
                    let location2 = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
                    let biasLocation = CLLocation(latitude: bias.latitude, longitude: bias.longitude)
                    return location1.distance(from: biasLocation) < location2.distance(from: biasLocation)
                }
            }
            
            completion(results, text)
        }
    }
}

struct AddressPrediction {
    let address: String
    let countryCity: String
    let coordinate: CLLocationCoordinate2D
}
