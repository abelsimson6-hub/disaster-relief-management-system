from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator, MinLengthValidator, RegexValidator

class Camp(models.Model):
    CAMP_TYPES = [
        ('shelter', 'Shelter'),
        ('medical', 'Medical'),
        ('distribution', 'Distribution'),
        ('evacuation', 'Evacuation'),
        ('rescue', 'Rescue Center'),
    ]
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('full', 'Full'),
        ('closed', 'Closed'),
        ('maintenance', 'Under Maintenance'),
    ]

    id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=200, validators=[MinLengthValidator(2)])
    camp_type = models.CharField(max_length=20, choices=CAMP_TYPES)
    disasters = models.ForeignKey('disasters.Disasters', on_delete=models.CASCADE)  # String reference
    location = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True,
                                   validators=[MinValueValidator(-90), MaxValueValidator(90)])
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True,
                                    validators=[MinValueValidator(-180), MaxValueValidator(180)])
    capacity = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(10000)])
    population_capacity = models.IntegerField(default=0, validators=[MinValueValidator(0), MaxValueValidator(20000)])
    contact_person = models.CharField(max_length=100)
    contact_phone = models.CharField(max_length=15,
                                     validators=[RegexValidator(regex=r'^\+?1?\d{9,15}$')])
    email = models.EmailField(blank=True)
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='active')
    coverage_radius_km = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True,
                                            validators=[MinValueValidator(0)])
    service_area_description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'camps'
        unique_together = ['name', 'disasters']
        indexes = [
            models.Index(fields=['camp_type', 'status']),
            models.Index(fields=['disasters']),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(camp_type__in=['shelter', 'medical', 'distribution', 'evacuation', 'rescue']),
                name='valid_camp_type'
            ),
            models.CheckConstraint(
                check=models.Q(status__in=['active', 'full', 'closed', 'maintenance']),
                name='valid_camp_status'
            ),
            models.CheckConstraint(
                check=models.Q(capacity__gte=1) & models.Q(capacity__lte=10000),
                name='valid_capacity_range'
            )
        ]

    def __str__(self):
        return f"{self.name} ({self.camp_type})"