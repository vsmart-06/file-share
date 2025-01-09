from django.http import HttpRequest, JsonResponse, HttpResponse
from django.contrib.auth import authenticate
from django.views.decorators.csrf import csrf_exempt
from file_share.models import *
import smtplib
from email.mime.text import MIMEText
import os
from dotenv import load_dotenv

load_dotenv()

GMAIL_PASSWORD = os.getenv("GMAIL_PASSWORD")

def index(request: HttpRequest):
    return HttpResponse("API is up and running")

@csrf_exempt
def signup(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    username = request.POST.get("username")
    email = request.POST.get("email")
    password = request.POST.get("password")

    if not username:
        return JsonResponse({"error": "'username' field is required"}, status = 400)
    if not email:
        return JsonResponse({"error": "'email' field is required"}, status = 400)
    if not password:
        return JsonResponse({"error": "'password' field is required"}, status = 400)

    try:
        user: UserCredentials = UserCredentials.objects.create_user(username = username, email = email, password = password)
        user.save()
    except Exception:
        return JsonResponse({"error": "A user with that email already exists"}, status = 400)
    
    message = MIMEText(f"Your OTP is {user.code}", "html")
    message["Subject"] = "OTP"
    message["From"] = "testsrivishnu@gmail.com"
    message["To"] = email

    session = smtplib.SMTP("smtp.gmail.com", 587)
    session.starttls()
    session.login("testsrivishnu@gmail.com", GMAIL_PASSWORD)
    session.sendmail("testsrivishnu@gmail.com", email, message.as_string())
    session.quit()

    return JsonResponse({"message": "User successfully signed up", "user_id": user.user_id})

@csrf_exempt
def login(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    username = request.POST.get("username")
    password = request.POST.get("password")

    if not username:
        return JsonResponse({"error": "'username' field is required"}, status = 400)
    if not password:
        return JsonResponse({"error": "'password' field is required"}, status = 400)

    user: UserCredentials = authenticate(request, username = username, password = password)

    if user:
        return JsonResponse({"message": "User successfully logged in", "user_id": user.user_id})
    
    return JsonResponse({"error": "Username or password is incorrect"}, status = 400)

@csrf_exempt
def check_code(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    user_id = int(request.POST.get("user_id"))
    code = request.POST.get("code")

    user: UserCredentials = UserCredentials.objects.get(user_id = user_id)

    if user.verified:
        return JsonResponse({"error": "User has already been verified"}, status = 400)
    
    if user.code != code:
        return JsonResponse({"error": "Incorrect code"}, status = 400)
    
    user.verified = True
    user.code = None
    user.time = None
    user.save()

    return JsonResponse({"message": "User verified successfully"})