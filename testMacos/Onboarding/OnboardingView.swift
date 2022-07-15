//
//  Onboarding.swift
//  testMacos
//
//  Created by Dilan Piscatello on 7/14/22.
//

import SwiftUI

struct OnboardingView: View {
    
    @State private var currentPage: OnboardingPage = .welcome
    @State private var previousPage: OnboardingPage = .welcome
    @State private var forward = true
    private let pages: [OnboardingPage]
    
    init(pages: [OnboardingPage]) {
        self.pages = pages
    }
    
    var body: some View {
        VStack {
            ForEach(pages, id: \.self) { page in
                if page == currentPage {
                    page.view(action: showBackPage)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(AnyTransition.asymmetric(
                            insertion: .move(edge: forward ? .trailing: .leading),
                            removal: .move(edge: forward ? .leading : .trailing)))
                        .animation(.default)
                }
            
            }
            
                HStack {
                   
                    Spacer()
                    if currentPage.shouldShowNextButton {
                    Button(action: showNextPage,
                            label: {
                        Text("Next")
                       
                        
                    })
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 50, bottom: 50, trailing: 50))
                .transition(AnyTransition.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading))
                           )
                .animation(.default)
            
        }
          
            .onAppear {
                self.currentPage = pages.first!
                
           
            }
    }
 
    private func showNextPage() {
        self.forward = true
        self.previousPage = currentPage
        guard let currentIndex = pages.firstIndex(of: currentPage), pages.count > currentIndex + 1 else {
            
            
            return
        }
        currentPage = pages[currentIndex + 1]
    }
    private func showBackPage() {
        self.forward = false
        self.previousPage = currentPage
        guard let currentIndex = pages.firstIndex(of: currentPage), 0 <= currentIndex - 1 else {
            print("else")
            return
        }
        
        currentPage = pages[currentIndex - 1]
    }
} 

//struct Onboarding_Previews: PreviewProvider {
//    static var previews: some View {
//        OnboardingView()
//    }
//}
