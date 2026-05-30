package com.jackdsql.app.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
public class MailerService {

    @Autowired
    private JavaMailSender mailSender;

    @Value("${MAIL_SOURCEMAIL}")
    private String sourceMail ;
    @Value("${BACKEND_URL:http://localhost:8080}")
    private String backendUrl;

    public void sendOtp(String toEmail , String otp) throws MessagingException {

        MimeMessage mimeMessage = mailSender.createMimeMessage();

        MimeMessageHelper mimeMessageHelper = new MimeMessageHelper(mimeMessage , true);

        mimeMessageHelper.setTo(toEmail);

        mimeMessageHelper.setFrom(sourceMail);

        mimeMessageHelper.setSubject("jackdsql - Reset your password");

        String html = """
                <div style="
                                font-family: Arial, sans-serif;
                                padding: 20px;
                                background-color: #f4f4f4;
                            ">
                                <div style="
                                    max-width: 500px;
                                    margin: auto;
                                    background: white;
                                    padding: 30px;
                                    border-radius: 10px;
                                    text-align: center;
                                ">
                                    <h2>Password Reset OTP</h2>
                
                                    <p>Your OTP for password reset is:</p>
                
                                    <div style="
                                        font-size: 32px;
                                        font-weight: bold;
                                        letter-spacing: 8px;
                                        margin: 20px 0;
                                        color: #2e7d32;
                                    ">
                                        %s
                                    </div>
                
                                    <p>
                                        This OTP is valid for
                                        <b>5 minutes</b>.
                                    </p>
                
                                    <p style="color: gray; font-size: 12px;">
                                        If you did not request this,
                                        please ignore this email.
                                    </p>
                                </div>
                            </div>
                """.formatted(otp);
        mimeMessageHelper.setText(html , true);
        mailSender.send(mimeMessage);
    }

    public void sendWelcomeMail(String mail) throws MessagingException{

        MimeMessage mimeMessage = mailSender.createMimeMessage();

        MimeMessageHelper mimeMessageHelper = new MimeMessageHelper(mimeMessage , true);

        mimeMessageHelper.setTo(mail);

        mimeMessageHelper.setFrom(sourceMail);

        mimeMessageHelper.setSubject("Welcome to jackdsql💪💪 - getting jacked in sql");

        String html = """
                <!DOCTYPE html>
                <html lang="en">
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>Welcome to JackDSQL</title>
                  <style>
                    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap');
                
                    body {
                      margin: 0;
                      padding: 0;
                      background-color: #10141a;
                      font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                      color: #dfe2eb;
                    }
                
                    .wrapper {
                      width: 100%%;
                      background-color: #10141a;
                      padding-bottom: 40px;
                    }
                
                    .main {
                      background-color: #1c2026;
                      margin: 40px auto 0 auto;
                      width: 100%%;
                      max-width: 600px;
                      border-radius: 16px;
                      border: 1px solid rgba(255, 255, 255, 0.05);
                      overflow: hidden;
                    }
                
                    .header {
                      background-color: #13171e;
                      padding: 40px 20px;
                      text-align: center;
                      border-bottom: 1px solid rgba(57, 255, 20, 0.15);
                    }
                
                    .logo {
                      width: 160px;
                      height: auto;
                    }
                
                    .content {
                      padding: 40px 30px;
                    }
                
                    h1 {
                      font-size: 28px;
                      font-weight: 700;
                      margin-top: 0;
                      margin-bottom: 16px;
                      color: #ffffff;
                      letter-spacing: -0.5px;
                    }
                
                    p {
                      font-size: 16px;
                      line-height: 1.6;
                      margin-top: 0;
                      margin-bottom: 24px;
                      color: #baccb0;
                    }
                
                    .code-block {
                      background-color: #090c10;
                      border: 1px solid rgba(57, 255, 20, 0.2);
                      border-radius: 8px;
                      padding: 16px 20px;
                      margin-bottom: 32px;
                      font-family: 'JetBrains Mono', monospace;
                      font-size: 14px;
                      color: #39FF14;
                      text-align: left;
                    }
                
                    .button-container {
                      text-align: center;
                      margin-top: 32px;
                      margin-bottom: 32px;
                    }
                
                    .btn {
                      background-color: #39FF14;
                      color: #000000 !important;
                      text-decoration: none;
                      padding: 16px 32px;
                      border-radius: 8px;
                      font-weight: 700;
                      font-size: 14px;
                      letter-spacing: 0.5px;
                      display: inline-block;
                      box-shadow: 0 4px 16px rgba(57, 255, 20, 0.35);
                      font-family: 'JetBrains Mono', monospace;
                    }
                
                    .footer {
                      padding: 30px 20px;
                      text-align: center;
                      background-color: #13171e;
                      border-top: 1px solid rgba(255, 255, 255, 0.05);
                    }
                
                    .footer-text {
                      font-size: 12px;
                      color: rgba(255, 255, 255, 0.3);
                      margin: 0;
                      font-family: 'JetBrains Mono', monospace;
                    }
                  </style>
                </head>
                <body>
                
                  <center class="wrapper">
                    <table class="main" width="100%%" border="0" cellspacing="0" cellpadding="0">
                      <tr>
                        <td class="header">
                          <img class="logo" src="%s/images/logoInCol.png" alt="JackDSQL Logo" />
                        </td>
                      </tr>
                      <tr>
                        <td class="content">
                          <h1>Welcome to the Grid, Developer.</h1>
                          <p>Your connection has been initialized successfully. You are now jacked into the ultimate SQL training system, designed to take your query compilation skills to the next level.</p>
                          
                          <div class="code-block">
                            <span>&gt; SELECT * FROM developers WHERE email = '%s';</span><br>
                            <span style="color: #ffffff;">&gt; Status: Connection Established [OK]</span>
                          </div>
                
                          <p>Get ready to tackle interactive queries, run schema evaluations in real-time, and climb the leaderboard challenges.</p>
                          
                          <div class="button-container">
                            <a href="%s" class="btn" target="_blank">LAUNCH SESSION</a>
                          </div>
                
                          <p style="font-size: 14px; color: rgba(255, 255, 255, 0.4); margin-bottom: 0;">If you did not request this authorization handshake, please disregard this transmission.</p>
                        </td>
                      </tr>
                      <tr>
                        <td class="footer">
                          <p class="footer-text">API: connected · DB: connected</p>
                          <p class="footer-text" style="margin-top: 8px;">© 2026 JackDSQL. All rights reserved.</p>
                        </td>
                      </tr>
                    </table>
                  </center>
                
                </body>
                </html>
                """.formatted(backendUrl, mail, backendUrl);

        mimeMessageHelper.setText(html , true);
        mailSender.send(mimeMessage);
    }
}
