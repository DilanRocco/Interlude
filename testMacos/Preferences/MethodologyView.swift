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
                        Text("Theory").fontWeight(.bold).font(.largeTitle).padding([.top, .bottom])
                        Spacer()
                    }
                InspirationView()
                BreaksView()
                ListView()
                DevelopedView()
            
                Spacer()
               
            }.padding([.leading, .trailing])
                       
            }.padding(0)
        }
}

struct InspirationView: View{
    var body: some View{
        Group{
            Text("Inspiration").fontWeight(.bold).font(.title2)
            Text("The Author, Jeffrey Anshel, from the book Visual Ergonomics Book, does a deep dive into the best practices for the human body when using a computer. With over 200 pages of analysis, I recommend that everyone take some time to at least skim through the ideas Mr. Anshel tries to explain. This book, written in 2005, is cited hundreds of times and acts as a golden handbook for adequately using a computer. From posture to a perfect desk lamp, this book covers a lot... So instead of focusing on every aspect of the book, I found one part quite interesting: Chapter 9 - Kids and Computers. However, I think that the chapter title is quite misleading. While the chapter mentions techniques for children and how they interact with computers, these rules still very much apply to adults. The book doesn't elaborate as much as I wished on the fact that adults can fall for the same mistakes children make. For example, Jeffrey Anshel says:").padding([.bottom], 10)
    
            Text("'Children may not be good at regulating their own computer usage and parents and teachers should be aware of the importance of appropriate intervals and encourage children to learn when to take breaks from computer use.'(Ashnel,153)").italic().padding([.bottom], 10)
            Text("I don't think Anshel believes that adults will fall culprit to usage problems, but rather, he believes children are much more prone to these issues - focusing on younger people. It's also worth mentioning that this book was written in 2005 when there weren't as many easily accessible addicting apps that keep you engaged for hours on end.")
    
           
        }.padding([.bottom], 10).frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct BreaksView: View {
    var body: some View {
        Group{
            Text("Solution").fontWeight(.bold).font(.title2)
            Text("Mr. Anshel spilts the latter part of the chapter 9 into four sections. Here is where I drew most of the inspiration for this app").padding([.bottom], 10)
            
            Text("Eye Breaks").fontWeight(.bold).font(.title3).padding([.bottom],1)
            Text("Looking at a computer screen for a while can cause some changes in how the eyes are working, for example, the rate of blinking will decrease which means that the tear film of the eye is not being refreshed and dirt and debris is not being cleaned from the eye surface as frequently as normal. Look away from the screen for a minute at something in the distance, preferable something more than 20 feet away to allow for the muscles in the eye to relax. (Ashnel, 169)")
            Text("Micro-breaks").fontWeight(.bold).font(.title3).padding([.bottom],1)
            Text("Most typing and mousing is done intermittently in bursts rather than as continious movements. So when you are on that intermit break, you should rest your hands in a relaxed, straight posture. Breaks every 15 minutes allows for decrease reports of eyestrain, blurred vision, and complaints of elbow and arm discomfort. Additionally, it allows for the most effecitent performance of computer tasks.(Ashnel, 169)")
            Text("Rest breaks").fontWeight(.bold).font(.title3).padding([.bottom],1)
            Text("To allow the body to improve blood circulation, and reduce the accumulation of static muscle fatigue, he recommends taking a brief rest break where they stand up, move around, and step away from the comupter. (Ashnel, 169)")
            Text("The Exercise breaks").fontWeight(.bold).font(.title3).padding([.bottom],1)
            Text("To reduce muscle fatigue, gentle exercises can be done every 1-2h. Specific examples of excersises that can be done are listed in Chapter 10 in the General Body Exercises section. (Ashnel, 169) A few listed below:")
        }.frame(maxWidth: .infinity, alignment: .leading).padding([.bottom],2)
        
    }
}

struct ListView: View {
        var body: some View {
            VStack{
                Group{
                    Text("• A Pectoral strech")
                    Text("• A Disk Reliever")
                    Text("• Pelvic Tilt")
                    Text("• Head Roll")
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }
}

struct DevelopedView: View {
        var body: some View {
            Group{
                Text("I developed this app to off of the techinques mentioned in this part of the book. Humans have trouble sticking to unregulated structure, so this app offloads that pressure so you don't have to remember when you last took a break. Even in the book, Ashnel even mentions that it would best to have an application built to instruct you when to break. (Ashnel, 153)").padding([.top,.bottom],2)
                Text("Source").fontWeight(.bold).font(.title3).padding([.bottom],1)
                Text("Ergonomics Handbook Information: Anshel, Jeffrey. Visual Ergonomics Handbook. CRC Press, Taylor & Francis Group, 2019")
                Link("Book Link", destination: URL(string: "https://routledge.com/Visual-Ergonomics-Handbook/Anshel/p/book/9780367392611")!).padding([.bottom], 10)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
}
