//
//  PromptTemplate.swift
//  book
//
//  Created by Dheeraj Gautam on 02/02/26.
//

import Foundation

enum PromptTemplate: String, CaseIterable {
    case short = "Short"
    case long = "Long"
    case solution = "Solution"
    
    var aiModel: AIModel {
        switch self {
        case .short:
            return .gpt35Turbo
        case .long:
            return .gpt4Turbo
        case .solution:
            return .gpt4oMini // Used when screenshots are attached
        }
    }
    
    var description: String {
        switch self {
        case .short:
            return """
            Short Prompt (< 100 words)
            • Model: GPT-3.5 Turbo
            • What: Concise, focused response
            • Why: Quick answers and summaries
            • Example: Brief explanations, definitions
            """
        case .long:
            return """
            Long Prompt (< 200 words)
            • Model: GPT-4 Turbo
            • What: Detailed, comprehensive response
            • Why: In-depth explanations and analysis
            • Example: Step-by-step guides, thorough breakdowns
            """
        case .solution:
            return """
            Solution Prompt (< 1000 words)
            • Model: GPT-4o Mini (with vision)
            • What: Complete problem-solving response
            • Why: Solve coding questions and technical problems
            • Example: Code solutions, debugging, explanations
            """
        }
    }
    
    func compile(with userText: String, resumeSummary: String = "") -> String {
        let resumeContext = resumeSummary.isEmpty ? "" : """
        
        CONTEXT ABOUT USER (from resume):
        \(resumeSummary)
        
        Use this context to personalize your response when relevant.
        
        """
        
        switch self {
        case .short:
            return """
            Please provide a SHORT and CONCISE response (less than 100 words).
            \(resumeContext)
            User question: \(userText)
            
            Keep your answer brief, focused, and to the point.
            """
        case .long:
            return """
            Please provide a DETAILED and COMPREHENSIVE response (less than 200 words).
            \(resumeContext)
            User question: \(userText)
            
            Include thorough explanations, examples, and relevant details.
            """
        case .solution:
            return """
            If you see any questions or coding questions, please solve them completely.
            \(resumeContext)
            Provide a COMPREHENSIVE SOLUTION with:
            • What: Clear explanation of the problem and solution
            • Why: Reasoning behind the approach
            • Example: Working code examples with explanations
            • Use bullet points for clarity
            • Keep response under 1000 words
            
            User question/problem: \(userText)
            
            Analyze the problem thoroughly and provide a complete, working solution.
            """
        }
    }
}
