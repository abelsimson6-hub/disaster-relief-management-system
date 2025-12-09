from django.db import models
from django.core.validators import MinLengthValidator, MinValueValidator

class Disasters(models.Model):
    DISASTER_TYPES = [
        ('earthquake', 'Earthquake'),
        ('flood', 'Flood'),
        ('hurricane', 'Hurricane'),
        ('tsunami', 'Tsunami'),
        ('fire', 'Fire'),
        ('landslide', 'Landslide'),
        ('drought', 'Drought'),
        ('other', 'Other'),
    ]
    SEVERITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ]
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('contained', 'Contained'),
        ('resolved', 'Resolved'),
    ]

    id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=200, validators=[MinLengthValidator(2)])
    disaster_type = models.CharField(max_length=20, choices=DISASTER_TYPES)
    severity = models.CharField(max_length=10, choices=SEVERITY_CHOICES)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='active')
    location = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    description = models.TextField()
    start_date = models.DateTimeField()
    end_date = models.DateTimeField(null=True, blank=True)
    estimated_damage = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)
    affected_areas = models.TextField(blank=True)
    affected_population_estimate = models.IntegerField(null=True, blank=True, validators=[MinValueValidator(0)])
    impact_radius_km = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True, validators=[MinValueValidator(0)])
    impact_area_description = models.TextField(blank=True)
    geojson_boundary = models.TextField(blank=True, help_text="Optional GeoJSON polygon for mapping.")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'disasters'
        
        indexes = [
            models.Index(fields=['disaster_type', 'status']),
            models.Index(fields=['severity']),
            models.Index(fields=['start_date']),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(disaster_type__in=['earthquake', 'flood', 'hurricane', 'tsunami', 'fire', 'landslide', 'drought', 'other']),
                name='valid_disaster_type'
            ),
            models.CheckConstraint(
                check=models.Q(severity__in=['low', 'medium', 'high', 'critical']),
                name='valid_severity_level'
            ),
            models.CheckConstraint(
                check=models.Q(status__in=['active', 'contained', 'resolved']),
                name='valid_status'
            ),
            models.CheckConstraint(
                check=models.Q(end_date__isnull=True) | models.Q(end_date__gt=models.F('start_date')),  # Fixed: double underscores
                name='valid_date_range'
            )
        ]
        ordering = ['-start_date']

    def __str__(self):  # Fixed: double underscores
        return f"{self.name} ({self.disaster_type})"