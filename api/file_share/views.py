import base64
from django.http import HttpRequest, JsonResponse, HttpResponse
from django.contrib.auth import authenticate
from django.views.decorators.csrf import csrf_exempt
from django.db.models import Q
from file_share.models import *
import smtplib
from email.mime.text import MIMEText
import datetime
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
            d = UserDevices.objects.filter(user = user).filter(Q(name = device_name) | Q(name__startswith = device_name + " (", name__endswith = ")")).only("name")
            devices = list(d.values())
            if devices == []:
                device = UserDevices(identifier = device_id, user = user, name = device_name, platform = platform)
            else:
                names = []
                for x in devices:
                    n: str = x["name"]
                    if n == device_name:
                        names.append(0)
                    else:
                        n = n.replace(device_name + " (", "", 1)[:-1]
                        try:
                            n = int(n)
                            names.append(n)
                        except:
                            continue
                
                names = list(set(names))
                names.sort()

                if names[-1] == len(names) - 1:
                    device = UserDevices(identifier = device_id, user = user, name = device_name + f" ({names[-1]+1})", platform = platform)
                else:
                    c = 0
                    for i in names:
                        if i != c:
                            break
                        c += 1
                    
                    device = UserDevices(identifier = device_id, user = user, name = device_name + f" ({c})", platform = platform)

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

    records = UserDevices.objects.filter(user = user).defer("user")
    data = list(records.values())
    
    return JsonResponse({"data": data})

@csrf_exempt
def modify_device(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    try:
        device_id = int(request.POST.get("device_id"))
    except:
        return JsonResponse({"error": "'device_id' field is required"}, status = 400)
    
    change = request.POST.get("change")
    name = request.POST.get("name")

    try:
        device = UserDevices.objects.get(device_id = device_id)
    except:
        return JsonResponse({"error": "A device with that device ID does not exist"}, status = 400)

    if change == "remove":
        device.delete()
    else:
        device.name = name
        device.save()
    
    return JsonResponse({"message": "Device modified successfully"})


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
        first: UserCredentials = UserCredentials.objects.get(user_id = contact["first_id"])
        second: UserCredentials = UserCredentials.objects.get(user_id = contact["second_id"])
        if first.user_id == user_id:
            data.append({"username": second.username, "email": second.email, "status": "approved" if contact["approved"] else "outgoing"})
        else:
            data.append({"username": first.username, "email": first.email, "status": "approved" if contact["approved"] else "incoming"})
    
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
    
    if first == second:
        return JsonResponse({"error": "You cannot create a contact with yourself"}, status = 400)

    try:
        UserContacts.objects.get(Q(first = first, second = second) | Q(first = second, second = first))
        return JsonResponse({"error": "A contact with this user already exists"}, status = 400)
    except:
        record = UserContacts(first = first, second = second)
        record.save()

    return JsonResponse({"message": "Contact request sent successfully"})

@csrf_exempt
def modify_contact(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    try:
        user_id = int(request.POST.get("user_id"))
    except:
        return JsonResponse({"error": "'user_id' field is required"}, status = 400)
    
    username = request.POST.get("username")
    change = request.POST.get("change")

    try:
        first: UserCredentials = UserCredentials.objects.get(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)
    
    try:
        second: UserCredentials = UserCredentials.objects.get(username = username)
    except:
        return JsonResponse({"error": f"A user with this username does not exist"}, status = 400)
    
    try:
        contact = UserContacts.objects.get(Q(first = first, second = second) | Q(first = second, second = first))
    except:
        return JsonResponse({"error": "The contact does not exist"}, status = 400)

    if change == "Accept":
        contact.approved = True
        contact.save()
    elif change != "Delete" and contact.approved:
        return JsonResponse({"error": "This contact cannot be declined or withdrawn"}, status = 400)
    else:
        contact.delete()
    
    return JsonResponse({"message": "Contact modified successfully"})

@csrf_exempt
def share_documents(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    try:
        user_id = int(request.POST.get("user_id"))
    except:
        return JsonResponse({"error": "'user_id' field is required"}, status = 400)
    
    identifier = request.POST.get("identifier")
    device_id = request.POST.get("device_id")
    username = request.POST.get("username")

    if not identifier:
        return JsonResponse({"error": "'identifier' field is required"}, status = 400)

    if not device_id and not username:
        return JsonResponse({"error": "Either 'device_id' or 'username' is required"}, status = 400)

    try:
        device_id = int(device_id)
    except:
        pass

    try:
        user: UserCredentials = UserCredentials.objects.get(user_id = user_id)
        sender: UserDevices = UserDevices.objects.get(user = user, identifier = identifier)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)
    
    if device_id:
        try:
            recipient_device: UserDevices = UserDevices.objects.get(device_id = device_id)
        except:
            return JsonResponse({"error": "A device with that device ID does not exist"}, status = 400)
    
    else:
        try:
            recipient_contact: UserCredentials = UserCredentials.objects.get(Q(username = username) | Q(email = username))
        except:
            return JsonResponse({"error": f"A user with this username does not exist"}, status = 400)
        

    files = {"documents": [{"name": file, "bytes": base64.b64encode(request.FILES.get(file).read()).decode()} for file in request.FILES]}
    
    share = SharedDocuments(sender_device = sender, sender_contact = user, data = files, timestamp = datetime.datetime.now(tz = datetime.timezone.utc))
    if device_id:
        share.recipient_device = recipient_device
    else:
        share.recipient_contact = recipient_contact
    
    share.save()

    return JsonResponse({"message": "Files share successfully"})

@csrf_exempt
def get_documents(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    records = SharedDocuments.objects.filter(Q(opened = False, timestamp__lte = (datetime.datetime.now(tz = datetime.timezone.utc) - datetime.timedelta(minutes = 10))) | Q(opened = True, timestamp__lte = (datetime.datetime.now(tz = datetime.timezone.utc) - datetime.timedelta(minutes = 5))))
    records.delete()

    try:
        user_id = int(request.POST.get("user_id"))
    except:
        return JsonResponse({"error": "'user_id' field is required"}, status = 400)
    
    identifier = request.POST.get("identifier")

    try:
        user_contact: UserCredentials = UserCredentials.objects.get(user_id = user_id)
        user_device: UserDevices = UserDevices.objects.get(user = user_contact, identifier = identifier)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)

    records = SharedDocuments.objects.filter(Q(recipient_device = user_device) | Q(recipient_contact = user_contact) | Q(sender_device = user_device) | Q(sender_contact = user_contact, recipient_device = None))
    documents = list(records.values())

    data = []
    for x in documents:
        if x["recipient_contact_id"]:
            a: UserCredentials = UserCredentials.objects.get(user_id = x["recipient_contact_id"] if user_contact.user_id != x["recipient_contact_id"] else x["sender_contact_id"])
            second = a.username
            device = False
        else:
            b: UserDevices = UserDevices.objects.get(device_id = x["recipient_device_id"] if user_device.device_id != x["recipient_device_id"] else x["sender_device_id"])
            second = b.name
            device = True

        data.append({"document_id": x["document_id"], "status": "outgoing" if x["sender_device_id"] == user_device.device_id else "incoming", "second": second, "is_device": device, "documents": x["data"]["documents"], "time": x["timestamp"].strftime("%Y-%m-%d %H:%M:%S %z")})
    
    return JsonResponse({"data": data})

@csrf_exempt
def open_document(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)

    try:
        document_id = int(request.POST.get("document_id"))
        document: SharedDocuments = SharedDocuments.objects.get(document_id = document_id)
    except ValueError:
        return JsonResponse({"error": "'document_id' field is required"}, status = 400)
    except:
        return JsonResponse({"error": "A document with that document ID does not exist"}, status = 400)
    
    document.opened = True
    document.save()

    return JsonResponse({"message": "Document opened successfully"})

@csrf_exempt
def delete_document(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    try:
        document_id = int(request.POST.get("document_id"))
        document: SharedDocuments = SharedDocuments.objects.get(document_id = document_id)
    except ValueError:
        return JsonResponse({"error": "'document_id' field is required"}, status = 400)
    except:
        return JsonResponse({"error": "A document with that document ID does not exist"}, status = 400)
    
    document.delete()

    return JsonResponse({"message": "Document deleted successfully"})
    