//
//  ContentView.swift
//  MedNES
//
//  Created by Stossy11 on 21/12/2024.
//  Fixed by 0-Blu
//

import SwiftUI

struct ContentView: View {
    @State var selectGame = false
    @State var gameURL: URL? = nil
        
    init() {
        DispatchQueue.main.async {
            SDL_SetMainReady()
            SDL_iPhoneSetEventPump(SDL_TRUE)
            
            if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER) < 0) {
                print("unable to init SDL")
            }
        }
    }
    
    var body: some View {
        VStack {
            Button {
                UserDefaults.standard.set(true, forKey: "isVirtualController")
                selectGame.toggle()
            } label: {
                Text("Select Game")
            }
        }
        .padding()
        .fileImporter(isPresented: $selectGame, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url):
                gameURL = url
                
                self.sstartEmu(url: url)
                
            case .failure:
                gameURL = nil
            }
        }
    }
    
    
    
    func sstartEmu(url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        
        patchMakeKeyAndVisible()
        
        let emu = startEmu(url.path)
        guard emu == 0 else { return }
        
        if scoped {
            url.stopAccessingSecurityScopedResource()
        }
    }
}


#Preview {
    ContentView()
}



func patchMakeKeyAndVisible() {
    let uiwindowClass = UIWindow.self
    if let m1 = class_getInstanceMethod(uiwindowClass, #selector(UIWindow.makeKeyAndVisible)),
       let m2 = class_getInstanceMethod(uiwindowClass, #selector(UIWindow.wdb_makeKeyAndVisible)) {
        method_exchangeImplementations(m1, m2)
    }
}



var theWindow: UIWindow? = nil
extension UIWindow {
    @objc func wdb_makeKeyAndVisible() {
        if #available(iOS 13.0, *) {
            self.windowScene = (UIApplication.shared.connectedScenes.first! as! UIWindowScene)
        }
        self.wdb_makeKeyAndVisible()
        theWindow = self
        print(theWindow?.layer.name)
        print(theWindow)
        if UserDefaults.standard.bool(forKey: "isVirtualController") {
            if theWindow != nil {
                waitforcontroller()
            }
        }
    }
}

func waitforcontroller() {
    if let window = theWindow {
        
        
        
        // Function to recursively search for GCControllerView
        func findGCControllerView(in view: UIView) -> UIView? {
            // Check if current view is GCControllerView
            if String(describing: type(of: view)) == "GameControllerView" {
                return view
            }
            
            // Search through subviews
            for subview in view.subviews {
                if let found = findGCControllerView(in: subview) {
                    return found
                }
            }
            
            return nil
        }
        
        var scale: CGFloat {
            if UIDevice().userInterfaceIdiom == .pad  {
                return 0.7
            }
            return 0.5
        }// = 0.5
        let newWidth = window.bounds.width * scale
        let newHeight = window.bounds.height * scale
        let originX = (window.bounds.width - newWidth) / 2
        let originY = window.bounds.height - newHeight
        

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if findGCControllerView(in: window) == nil {
                
            }
        }

    }
}
