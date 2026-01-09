from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import RegexValidator, MinValueValidator, MaxValueValidator

# ----------------------------
# User Model
# ----------------------------
from django.contrib.auth.models import BaseUserManager

class CustomUserManager(BaseUserManager):
    def create_user(self, username, email=None, password=None, **extra_fields):
        if not username:
            raise ValueError('The Username must be set')
        email = self.normalize_email(email)
        extra_fields.setdefault('is_active', True)
        if 'role' not in extra_fields:
            extra_fields['role'] = 'volunteer'  # default for normal users
        user = self.model(username=username, email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, username, email=None, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', 'super_admin')  # important fix ✅

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')
        return self.create_user(username, email, password, **extra_fields)

class User(AbstractUser):
    ROLE_CHOICES = [
        ('super_admin', 'Super Admin'),
        ('camp_admin', 'Camp Admin'),
        ('volunteer', 'Volunteer'),
        ('victim', 'Victim'),
        ('donor', 'Donor'),
    ]

    role = models.CharField(max_length=20, choices=ROLE_CHOICES,default='volunteer')
    phone = models.CharField(
        max_length=15,
        blank=True,
        validators=[RegexValidator(regex=r'^\+?1?\d{9,15}$', message='Enter a valid phone number')]
    )
    address = models.TextField(blank=True)
    # Location fields for location-based features
    current_location = models.CharField(max_length=255, blank=True, help_text="Current location address")
    latitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True,
        validators=[MinValueValidator(-90), MaxValueValidator(90)],
        help_text="Latitude coordinate"
    )
    longitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True,
        validators=[MinValueValidator(-180), MaxValueValidator(180)],
        help_text="Longitude coordinate"
    )
    location_updated_at = models.DateTimeField(null=True, blank=True, help_text="When location was last updated")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    objects = CustomUserManager()


    class Meta:
        db_table = 'users'
        indexes = [
            models.Index(fields=['role']),
            models.Index(fields=['username']),
            models.Index(fields=['latitude', 'longitude']),  # For location-based queries
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(role__in=('super_admin', 'camp_admin', 'volunteer', 'victim', 'donor')),
                name='valid_user_role'
            )
        ]

    def __str__(self):
        return f"{self.username} ({self.role})"

    @classmethod
    def create_superuser(cls, username, email=None, password=None, **extra_fields):
        extra_fields.setdefault('role', 'super_admin')
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        if extra_fields['role'] not in dict(cls.ROLE_CHOICES):
            raise ValueError(f"Superuser role must be one of {list(dict(cls.ROLE_CHOICES).keys())}")

        return cls.objects.create_user(username, email, password, **extra_fields)


# ----------------------------
# Volunteer Model
# ----------------------------
class Volunteer(models.Model):
    id = models.AutoField(primary_key=True)
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        limit_choices_to={'role': 'volunteer'}
    )
    availability = models.BooleanField(default=True)
    experience = models.TextField(blank=True)
    join_date = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'volunteers'

    def __str__(self):
        return f"Volunteer: {self.user.username}"


# ----------------------------
# Volunteer Skill Model
# ----------------------------
class VolunteerSkill(models.Model):
    PROFICIENCY_CHOICES = [
        ('beginner', 'Beginner'),
        ('intermediate', 'Intermediate'),
        ('expert', 'Expert'),
    ]

    id = models.AutoField(primary_key=True)
    volunteer = models.ForeignKey(Volunteer, on_delete=models.CASCADE, related_name='skills')
    skill = models.CharField(max_length=100)
    proficiency = models.CharField(max_length=20, choices=PROFICIENCY_CHOICES)

    class Meta:
        db_table = 'volunteer_skills'
        unique_together = ['volunteer', 'skill']
        constraints = [
            models.CheckConstraint(
                check=models.Q(proficiency__in=('beginner', 'intermediate', 'expert')),
                name='valid_proficiency_level'
            )
        ]

    def __str__(self):
        return f"{self.volunteer.user.username} - {self.skill} ({self.proficiency})"


# ----------------------------
# Victim Model
# ----------------------------
class Victim(models.Model):
    id = models.AutoField(primary_key=True)
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        limit_choices_to={'role': 'victim'}
    )
    age = models.IntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(0), MaxValueValidator(120)]
    )
    family_members = models.IntegerField(
        default=1,
        validators=[MinValueValidator(0), MaxValueValidator(20)]
    )
    emergency_contact = models.CharField(
        max_length=15,
        blank=True,
        validators=[RegexValidator(regex=r'^\+?1?\d{9,15}$', message='Enter a valid phone number')]
    )
    special_needs = models.TextField(blank=True)
    medical_conditions = models.TextField(blank=True)
    priority_level = models.CharField(
        max_length=10,
        choices=[
            ('low', 'Low'),
            ('medium', 'Medium'),
            ('high', 'High'),
            ('critical', 'Critical'),
        ],
        default='medium'
    )
    is_high_risk = models.BooleanField(default=False)
    emergency_supplies_needed = models.TextField(blank=True)
    registration_date = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'victims'
        constraints = [
            models.CheckConstraint(
                check=models.Q(age__gte=0) & models.Q(age__lte=120),
                name='valid_age_range'
            ),
            models.CheckConstraint(
                check=models.Q(family_members__gte=0) & models.Q(family_members__lte=20),
                name='valid_family_members'
            )
        ]

    def __str__(self):
        return f"Victim: {self.user.username}"


# ----------------------------
# Camp Admin Model
# ----------------------------
class CampAdmin(models.Model):
    id = models.AutoField(primary_key=True)
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        limit_choices_to={'role': 'camp_admin'}
    )
    camp = models.ForeignKey('shelters.Camp', on_delete=models.CASCADE)
    assigned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'camp_admins'
        unique_together = ['user', 'camp']

    def __str__(self):
        return f"Camp Admin: {self.user.username} ({self.camp.name})"
