# Generated by Django 5.1.2 on 2025-01-10 10:05

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('file_share', '0003_usercontacts_userdevices_shareddocuments'),
    ]

    operations = [
        migrations.AlterField(
            model_name='userdevices',
            name='os',
            field=models.TextField(choices=[('ios', 'ios'), ('android', 'android'), ('windows', 'windows'), ('macos', 'macos'), ('linux', 'linux')]),
        ),
    ]
