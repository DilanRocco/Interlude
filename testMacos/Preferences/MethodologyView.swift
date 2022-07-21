//
//  MethodologyView.swift
//  testMacos
//
//  Created by Dilan Piscatello on 5/4/22.
//

import SwiftUI

struct MethodologyView: View {
        var body: some View {
            ScrollView{
            VStack{
                HStack{
                    Text("Theory").fontWeight(.bold).font(.largeTitle).padding(0).padding([.bottom], 20).padding([.top],.none)
                    Spacer()
                }
            
                Group{
                    Text("Inspiration").fontWeight(.bold).font(.title2) .frame(maxWidth: .infinity, alignment: .leading).padding([.bottom], 15)
                    Text("The Author Jeffrey Anshel from the book Viusal Ergonomics Book does a deep dive into the best practices for the human body when using a computer. With over 200 pages of analysis, I would recommended that everyone takes some time to at least skim through the ideas Mr. Anshel tries to explain. Cited hundreds of times, this book written in 2005 acts as a golden handbook for proper use of a computer. From posture to a perfect desk lamp, this book covers a lot... So instead of focusing on every aspect of the book, I found one part of the book quite interesting: Chapter 9 - Kids and Computers. However, I think that the chapter title is a quite misleading. While the chapter does mention techinques for children and the way they interact with computers, these rules still very much apply for us adults. The book doesn't elobarate as much as I wished on the fact that adults can fall for the same mistakes children make. For example, Jeffrey Anshel says:").padding([.bottom], 10)
                
                    Text("'Children may not be good at regulating their own computer usage and parents and teachers should be aware of the importance of appropriate intervals and encourage children to learn when to take breaks from computer use.'(Ashnel,153)").italic().padding([.bottom], 10)
                
                Text("I don't think Asnhel believes that adults won't fall culprit to usage problems; however, that he belives children are much more prone to these issues - therefore focusing on younger people. It's also worth mentioning that this book was written in 2005 when there weren't as many easy accessible addicting apps that keep you engaged for hours on end.").padding([.bottom], 10)
                
            
                   
                Text("Solution").fontWeight(.bold).frame(maxWidth: .infinity, alignment: .leading).font(.title2).padding([.bottom], 15)
                    Text("Mr. Anshel spilts the latter part of the chapter 9 into four sections.").padding([.bottom], 10).padding([.leading], .none).padding([.leading],-65).multilineTextAlignment(.leading)
                }
                BreaksView()
                ListView()
                DevelopedView()
            
                Spacer()
            }.padding([.leading, .trailing]).frame(maxWidth: .infinity, alignment: .leading)
                       
            }.padding(0)
        }
}

struct BreaksView: View {
    var body: some View {
        VStack{
            Text("Eye Breaks").fontWeight(.bold).font(.title3).frame(maxWidth: .infinity, alignment: .leading).padding([.bottom],1)
    Text("Looking at a computer screen for a while can cause some changes in how the eyes are working, for example, the rate of blinking will decrease which means that the tear film of the eye is not being refreshed and dirt and debris is not being cleaned from the eye surface as frequently as normal. Look away from the screen for a minute at something in the distance, preferable something more than 20 feet away to allow for the muscles in the eye to relax.").padding([.bottom],2)
    
    
    Text("Micro-breaks").fontWeight(.bold).font(.title3).frame(maxWidth: .infinity, alignment: .leading).padding([.bottom],1)
    Text("Looking at a computer screen for a while can cause some changes in how the eyes are working, for example, the rate of blinking will decrease which means that the tear film of the eye is not being refreshed and dirt and debris is not being cleaned from the eye surface as frequently as normal. Look away from the screen for a minute at something in the distance, preferable something more than 20 feet away to allow for the muscles in the eye to relax.").padding([.bottom],2)
    
    Text("Rest breaks").fontWeight(.bold).font(.title3).frame(maxWidth: .infinity, alignment: .leading).padding([.bottom],1)
    Text("To allow the body to improve blood circulation, and reduce the accumulation of static muscle fatigue, he recommends taking a brief rest break where they stand up, move around, and step away from the comupter.").padding([.bottom],2)

            
        
    Text("The Exercise breaks").fontWeight(.bold).font(.title3).frame(maxWidth: .infinity, alignment: .leading).padding([.bottom],1)
            Text("To reduce muscle fatigue, gentle exercises can be done every 1-2h. Specific examples of excersises that can be done are listed in Chapter 10 in the General Body Exercises section. (Ashnel, 169) A few listed below:").padding([.bottom],2)
    }
    }
}

struct ListView: View {
        var body: some View {
            VStack{
            Text("• A Pectoral strech").frame(maxWidth: .infinity, alignment: .leading)
            Text("• A Disk Reliever").frame(maxWidth: .infinity, alignment: .leading)
            Text("• Pelvic Tilt").frame(maxWidth: .infinity, alignment: .leading)
            Text("• Head Roll").frame(maxWidth: .infinity, alignment: .leading)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
}
struct DevelopedView: View {
        var body: some View {
            VStack{
                Text("I developed this app to remind you to particapte in these breaks. Humans have trouble sticking to unguided structure, so this app offloads that pressure so you don't have to remember when you last took a break. Even in the book, Ashnel even mentions that it would best to have an application built to instruct you when to break. (Ashnel, 153)").padding([.top],2).padding([.bottom],2)
                Text("Source").fontWeight(.bold).font(.title3).frame(maxWidth: .infinity, alignment: .leading).padding([.bottom],1)
                Text("Ergonomics Handbook Information: Anshel, Jeffrey. Visual Ergonomics Handbook. CRC Press, Taylor & Francis Group, 2019")
                Link("Book Link", destination: URL(string: "https://routledge.com/Visual-Ergonomics-Handbook/Anshel/p/book/9780367392611")!)


            }.frame(maxWidth: .infinity, alignment: .leading)
        }
}
//struct MethodologyView_Previews: PreviewProvider {
//    static var previews: some View {
//        MethodologyView()
//    }
////}
