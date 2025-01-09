import smtplib
from email.mime.text import MIMEText
import os
from dotenv import load_dotenv

load_dotenv()

GMAIL_PASSWORD = os.getenv("GMAIL_PASSWORD")

email = "srivishnuvusirikala@gmail.com"

message = MIMEText(f"Your OTP is {"user.code"}", "html")
message["Subject"] = "OTP"
message["From"] = "testsrivishnu@gmail.com"
message["To"] = email

session = smtplib.SMTP("smtp.gmail.com", 587)
session.starttls()
session.login("testsrivishnu@gmail.com", GMAIL_PASSWORD)
session.sendmail("testsrivishnu@gmail.com", email, message.as_string())
session.quit()