package com.jackdsql.app.controllers;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class Health {

    @GetMapping(value = "/health",produces = "text/html")
    public String healthCheck(){
        return """
       <!DOCTYPE html>
                   <html lang="en">
                   <head>
                       <meta charset="UTF-8">
                       <meta name="viewport" content="width=device-width, initial-scale=1.0">
                       <title>Backend Status</title>
                
                       <style>
                           * {
                               margin: 0;
                               padding: 0;
                               box-sizing: border-box;
                               font-family: 'Segoe UI', system-ui, sans-serif;
                           }
                
                           body {
                               height: 100vh;
                               background: linear-gradient(135deg, #0f172a, #1e293b);
                               color: #e2e8f0;
                               display: flex;
                               align-items: center;
                               justify-content: center;
                           }
                
                           .container {
                               text-align: center;
                               padding: 40px;
                               border-radius: 20px;
                               background: rgba(255,255,255,0.05);
                               backdrop-filter: blur(12px);
                               box-shadow: 0 10px 40px rgba(0,0,0,0.4);
                               width: 90%;
                               max-width: 500px;
                           }
                
                           .status {
                               font-size: 60px;
                               margin-bottom: 10px;
                           }
                
                           .title {
                               font-size: 28px;
                               font-weight: 600;
                           }
                
                           .subtitle {
                               margin-top: 10px;
                               font-size: 14px;
                               color: #94a3b8;
                           }
                
                           .badge {
                               margin-top: 20px;
                               display: inline-block;
                               padding: 8px 16px;
                               border-radius: 999px;
                               background: #22c55e;
                               color: #022c22;
                               font-weight: 600;
                               font-size: 14px;
                           }
                
                           .info {
                               margin-top: 25px;
                               font-size: 13px;
                               color: #cbd5f5;
                           }
                
                           .footer {
                               margin-top: 30px;
                               font-size: 12px;
                               color: #64748b;
                           }
                
                           .pulse {
                               display: inline-block;
                               width: 10px;
                               height: 10px;
                               background: #22c55e;
                               border-radius: 50%;
                               margin-right: 8px;
                               animation: pulse 1.5s infinite;
                           }
                
                           @keyframes pulse {
                               0% { transform: scale(1); opacity: 1; }
                               50% { transform: scale(1.6); opacity: 0.5; }
                               100% { transform: scale(1); opacity: 1; }
                           }
                
                       </style>
                   </head>
                   <body>
                
                   <div class="container">
                       <div class="status">🚀</div>
                
                       <div class="title">Backend is Running</div>
                       <div class="subtitle">Spring Boot server is live and operational</div>
                
                       <div class="badge">
                           <span class="pulse"></span>
                           Healthy
                       </div>
                
                       <div class="info">
                           <p><strong>Port:</strong> 8080</p>
                           <p><strong>Status:</strong> Connected to Database</p>
                           <p><strong>Environment:</strong> Production Ready</p>
                       </div>
                
                       <div class="footer">
                           Powered by Spring Boot • Your API is ready 🚀
                       </div>
                   </div>
                
                   </body>
                   </html>
    """;
    }
}
