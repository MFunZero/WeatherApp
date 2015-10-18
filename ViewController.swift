//
//  ViewController.swift
//  WeatherApp
//
//  Created by suze on 15/10/15.
//  Copyright © 2015年 suze. All rights reserved.
//

import UIKit
import CoreLocation
class ViewController: UIViewController ,CLLocationManagerDelegate{
    @IBOutlet weak var downloading: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var dayOrNight: UIImageView!
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var icon: UIImageView!

    
    var city:NSDictionary?
    let locationManager:CLLocationManager = CLLocationManager()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.indicator.hidesWhenStopped = true

        self.navigationController?.navigationBarHidden = true
        self.indicator.startAnimating()
        self.downloading.text = "正在加载中..."
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if ios8(){
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.startUpdatingLocation()
    }

    func ios8()->Bool{
        let current = UIDevice.currentDevice().systemVersion
        return current >= "8.0"
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location:CLLocation = locations[locations.count-1] as CLLocation
        if location.horizontalAccuracy > 0 {
            print(location.coordinate.latitude)
            print(location.coordinate.longitude)
            print("\(location.coordinate)"	)
            //self.reloadData(location)
            
            var geocoder = CLGeocoder()
            var p:CLPlacemark?
            geocoder.reverseGeocodeLocation(location, completionHandler: {
            (placemarks, error) -> Void in
            //强制转成简体中文
            var array = NSArray(object: "zh-hans")
            NSUserDefaults.standardUserDefaults().setObject(array, forKey: "AppleLanguages")
            //显示所有信息
            if error != nil {
                //println("错误：\(error.localizedDescription))")
                 self.reloadData()
                return
            }
            let pm = placemarks!
            if pm.count > 0{
                p = placemarks![0] as? CLPlacemark
                //println(p) //输出反编码信息
               
                var name:String = (p?.name)!
                self.location.text = name
                self.updateWeatherInfo(name)
            } else {
                NSLog("反编码地理信息出错，现采用ip地理位置获取")
               
            }
        })
     locationManager.stopUpdatingLocation()
                
        }
    }
    func reloadData(){
        var strurl = NSString(format:"http://api.map.baidu.com/location/ip?ak=%@", "3agUD6jmdv87GFRKXMTvOlSD")
        strurl = strurl.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let surl = NSURL(string: strurl as String)
        var request = NSURLRequest(URL: surl!)
        var error:NSError?
        do {
            var data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: nil)
            var resDict =  try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
            self.city = resDict
            print("\(self.city)")
        }catch {
            NSLog("请求失败")
            self.downloading.text = "地理位置获取失败，请确认是否联网"
            
        }
        
        var  resultCode = city!.objectForKey("status") as! Int
        print(resultCode)
        if resultCode == 0 {
           
            var cityName = city!["content"]?.objectForKey("address_detail")?.objectForKey("city") as! String
            print(cityName)
//           var range = cityName.rangeOfString("市")
//                       print("\(range)")
//            cityName.removeRange(range!)

            //使用扩展将城市名字去掉“市”汉字，便于直接用城市名字查询天气
            var name = cityName.str(cityName)
            self.location.text = name
            
            self.location.font = UIFont.boldSystemFontOfSize(35)
            self.location.textColor = UIColor.whiteColor()
            
            self.updateWeatherInfo(name)
        }else {
            let alertView = UIAlertView(title: "Error Message", message: "请求地理位置出错", delegate: nil, cancelButtonTitle: "OK")
            alertView.show()
        }
    }
       func updateWeatherInfo(cityName:String){
        let manager = AFHTTPRequestOperationManager()

        
        let url =
        "http://apistore.baidu.com/microservice/weather?"
        let params = ["cityname":cityName]
       var  test:AnyObject?
        manager.GET(url,parameters: params,
            success:{
                (operation: AFHTTPRequestOperation!,responseObject:AnyObject!) in
                test = responseObject
                if  test == nil {
                    self.downloading.text = "请求天气信息出错，请检查网络后重试哦..."
                    self.indicator.stopAnimating()
                
//                let alertView = UIAlertView(title: "Error Message", message: "请求天气信息出错", delegate: nil, cancelButtonTitle: "OK")
//                 alertView.show()
                   
                }else{
                print("JSON:" + (test!.description))
                    self.updateUISuccess(responseObject as! NSDictionary)}
            },failure:{(operation:AFHTTPRequestOperation!,error:NSError!) in print("Error:" + error.localizedDescription)

        })
            
        }
    func updateUISuccess(jsonResult:NSDictionary){
        self.indicator.stopAnimating()
        self.downloading.text = nil
      

        
        let result = jsonResult["retData"] as! NSDictionary
        let temp = result["temp"] as! String
        self.temperature.text = "\(temp)℃"
        self.temperature.font = UIFont.boldSystemFontOfSize(30)
        self.temperature.textColor = UIColor.whiteColor()
        let condition = result["weather"] as! String
        print("\(condition)")
        let sunrise = result.objectForKey("sunrise") as? Double
        let sunset = result.objectForKey("sunset") as? Double
        
        var nightTime = false
        let now = NSDate().timeIntervalSince1970
        if now < sunrise || now > sunset {
            nightTime = true
        }
        self.updateWeatherIcon(condition,nightTime:nightTime)
        
    }
    func updateWeatherIcon(condition:String,nightTime:Bool){
        
            if nightTime {
                self.dayOrNight.image = UIImage(named:"qing")
            } else {
                self.dayOrNight.image = UIImage(named: "yejian")
            }
         if condition.containsString("晴") {
            self.icon.image = UIImage(named: "qing")
        }
         else if condition.containsString("雨"){
           self.icon.image = UIImage(named: "rain")
         }else if condition.containsString("霾"){
            self.icon.image = UIImage(named: "cloud")
         }else {
            self.icon.image = UIImage(named: "qingzhuanduoyun")
        }
        
    
    }
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        self.reloadData()
        print(error)
    }


}

