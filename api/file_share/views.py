from django.http import HttpRequest, JsonResponse, HttpResponse
from django.contrib.auth import authenticate
from django.views.decorators.csrf import csrf_exempt
from django.db.models import Q
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
    device_id = request.POST.get("device_id")
    device_name = request.POST.get("device_name")
    platform = request.POST.get("platform")

    if not username:
        return JsonResponse({"error": "'username' field is required"}, status = 400)
    if not password:
        return JsonResponse({"error": "'password' field is required"}, status = 400)
    if not device_id:
        return JsonResponse({"error": "'device_id' field is required"}, status = 400)
    if not device_name:
        return JsonResponse({"error": "'device_name' field is required"}, status = 400)
    if not platform:
        return JsonResponse({"error": "'platform' field is required"}, status = 400)

    user: UserCredentials = authenticate(request, username = username, password = password)

    if user and user.verified:
        try:
            UserDevices.objects.get(identifier = device_id, user = user, platform = platform)
        except:
            device = UserDevices(identifier = device_id, user = user, name = device_name, platform = platform)
            device.save()

        return JsonResponse({"message": "User successfully logged in", "user_id": user.user_id})
    
    elif user and not user.verified:
        return JsonResponse({"error": "User has not been verified yet"})
    
    return JsonResponse({"error": "Username or password is incorrect"}, status = 400)

@csrf_exempt
def check_code(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    try:
        user_id = int(request.POST.get("user_id"))
    except:
        return JsonResponse({"error": "'user_id' field is required"}, status = 400)
    
    code = request.POST.get("code")
    device_id = request.POST.get("device_id")
    device_name = request.POST.get("device_name")
    platform = request.POST.get("platform")

    if not code:
        return JsonResponse({"error": "'code' field is required"}, status = 400)
    if not device_id:
        return JsonResponse({"error": "'device_id' field is required"}, status = 400)
    if not device_name:
        return JsonResponse({"error": "'device_name' field is required"}, status = 400)
    if not platform:
        return JsonResponse({"error": "'platform' field is required"}, status = 400)

    try:
        user: UserCredentials = UserCredentials.objects.get(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)

    if user.verified:
        return JsonResponse({"error": "User has already been verified"}, status = 400)
    
    if user.code != code:
        return JsonResponse({"error": "Incorrect code"}, status = 400)
    
    user.verified = True
    user.code = None
    user.time = None
    user.save()

    device = UserDevices(identifier = device_id, user = user, name = device_name, platform = platform)
    device.save()

    return JsonResponse({"message": "User verified successfully", "user_id": user.user_id})

@csrf_exempt
def get_devices(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    try:
        user_id = int(request.POST.get("user_id"))
    except:
        return JsonResponse({"error": "'user_id' field is required"}, status = 400)
    
    try:
        user: UserCredentials = UserCredentials.objects.get(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)

    records = UserDevices.objects.filter(user = user)
    devices = list(records.values())

    data = []
    for x in devices:
        data.append({"name": x["name"], "platform": x["platform"], "count": data.count(x["name"])})
    
    return JsonResponse({"data": data})

@csrf_exempt
def get_contacts(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    try:
        user_id = int(request.POST.get("user_id"))
    except:
        return JsonResponse({"error": "'user_id' field is required"}, status = 400)
    
    try:
        user: UserCredentials = UserCredentials.objects.get(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)

    records = UserContacts.objects.filter(Q(first = user) | Q(second = user))
    contacts = list(records.values())

    data = []

    for contact in contacts:
        if contact["first"].user_id == user_id:
            data.append({"username": contact["second"].username, "email": contact["second"].email, "status": "approved" if contact["approved"] else "outgoing"})
        else:
            data.append({"username": contact["first"].username, "email": contact["first"].email, "status": "approved" if contact["approved"] else "incoming"})
    
    return JsonResponse({"data": data})

@csrf_exempt
def add_contact(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    try:
        user_id = int(request.POST.get("user_id"))
    except:
        return JsonResponse({"error": "'user_id' field is required"}, status = 400)
    
    name = request.POST.get("second")

    try:
        first: UserCredentials = UserCredentials.objects.get(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)
    
    try:
        second: UserCredentials = UserCredentials.objects.get(email = name) if "@" in name else UserCredentials.objects.get(username = name)
    except:
        return JsonResponse({"error": f"A user with this {'email' if '@' in name else 'username'} does not exist"}, status = 400)
    
    record = UserContacts(first = first, second = second)
    record.save()

    return JsonResponse({"message": "Contact request sent successfully"})