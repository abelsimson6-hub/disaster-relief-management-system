"""
Django management command to create initial test data for the DRMS system.

This command creates test data for all major models:
- Users (super_admin, camp_admin, volunteers, victims, donors)
- Disasters
- Resources
- Camps/Shelters
- Donations
- Volunteers, Victims, Camp Admins
- Alerts and Weather Alerts
- Help Requests and Task Assignments
- Transport

Usage:
    python manage.py setup_test_data
    
    # To clear existing data first:
    python manage.py setup_test_data --clear
"""

from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal

from users.models import User, Volunteer, Victim, CampAdmin, VolunteerSkill
from disasters.models import Disasters
from relief.models import Resource, ResourceRequest
from shelters.models import Camp
from operations.models import Donation, DonationItem, Transport, HelpRequest, TaskAssignment
from alerts.models import Alert, WeatherAlert


class Command(BaseCommand):
    help = 'Creates initial test data for the DRMS system'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing test data before creating new data',
        )

    def handle(self, *args, **options):
        if options['clear']:
            self.stdout.write(self.style.WARNING('Clearing existing test data...'))
            self._clear_data()
        
        self.stdout.write(self.style.SUCCESS('Creating test data...'))
        
        # Create in dependency order
        users = self._create_users()
        disasters = self._create_disasters()
        resources = self._create_resources()
        camps = self._create_camps(disasters, users)
        self._create_user_profiles(users, camps)
        self._create_donations(users, resources)
        self._create_alerts(disasters, users)
        self._create_weather_alerts(users, disasters)
        self._create_transport(camps)
        self._create_help_requests(users, disasters)
        self._create_resource_requests(camps, resources, users)
        
        self.stdout.write(self.style.SUCCESS('\n[SUCCESS] Test data created successfully!'))
        self.stdout.write(self.style.SUCCESS('\nTest Users Created:'))
        self.stdout.write('  Super Admin: admin / password123')
        self.stdout.write('  Camp Admin: campadmin1 / password123')
        self.stdout.write('  Volunteer: volunteer1 / password123')
        self.stdout.write('  Victim: victim1 / password123')
        self.stdout.write('  Donor: donor1 / password123')

    def _clear_data(self):
        """Clear existing test data"""
        TaskAssignment.objects.all().delete()
        HelpRequest.objects.all().delete()
        ResourceRequest.objects.all().delete()
        DonationItem.objects.all().delete()
        Donation.objects.all().delete()
        Transport.objects.all().delete()
        WeatherAlert.objects.all().delete()
        Alert.objects.all().delete()
        VolunteerSkill.objects.all().delete()
        Volunteer.objects.all().delete()
        Victim.objects.all().delete()
        CampAdmin.objects.all().delete()
        Camp.objects.all().delete()
        Resource.objects.all().delete()
        Disasters.objects.all().delete()
        # Note: We don't delete superuser/admin users, only test users
        User.objects.filter(username__in=['campadmin1', 'volunteer1', 'volunteer2', 'victim1', 'victim2', 'donor1']).delete()

    def _create_users(self):
        """Create test users"""
        users = {}
        
        # Super Admin (create if doesn't exist)
        admin, created = User.objects.get_or_create(
            username='admin',
            defaults={
                'email': 'admin@drms.local',
                'first_name': 'Super',
                'last_name': 'Admin',
                'phone': '+1234567890',
                'address': '123 Admin Street',
                'role': 'super_admin',
                'is_staff': True,
                'is_superuser': True,
                'is_active': True,
            }
        )
        if created:
            admin.set_password('password123')
            admin.save()
        users['admin'] = admin

        # Camp Admin
        camp_admin, created = User.objects.get_or_create(
            username='campadmin1',
            defaults={
                'email': 'campadmin1@drms.local',
                'first_name': 'Camp',
                'last_name': 'Admin',
                'phone': '+1234567891',
                'address': '456 Camp Street',
                'role': 'camp_admin',
                'is_active': True,
            }
        )
        if created:
            camp_admin.set_password('password123')
            camp_admin.save()
        users['camp_admin'] = camp_admin

        # Volunteers
        for i in range(1, 3):
            username = f'volunteer{i}'
            volunteer, created = User.objects.get_or_create(
                username=username,
                defaults={
                    'email': f'{username}@drms.local',
                    'first_name': f'Volunteer{i}',
                    'last_name': 'Helper',
                    'phone': f'+123456789{i+1}',
                    'address': f'{100+i} Volunteer Ave',
                    'role': 'volunteer',
                    'is_active': True,
                }
            )
            if created:
                volunteer.set_password('password123')
                volunteer.save()
            users[f'volunteer{i}'] = volunteer

        # Victims
        for i in range(1, 3):
            username = f'victim{i}'
            victim, created = User.objects.get_or_create(
                username=username,
                defaults={
                    'email': f'{username}@drms.local',
                    'first_name': f'Victim{i}',
                    'last_name': 'Test',
                    'phone': f'+123456790{i}',
                    'address': f'{200+i} Disaster Zone',
                    'role': 'victim',
                    'is_active': True,
                }
            )
            if created:
                victim.set_password('password123')
                victim.save()
            users[f'victim{i}'] = victim

        # Donor
        donor, created = User.objects.get_or_create(
            username='donor1',
            defaults={
                'email': 'donor1@drms.local',
                'first_name': 'Generous',
                'last_name': 'Donor',
                'phone': '+1234567999',
                'address': '789 Donor Blvd',
                'role': 'donor',
                'is_active': True,
            }
        )
        if created:
            donor.set_password('password123')
            donor.save()
        users['donor'] = donor

        return users

    def _create_disasters(self):
        """Create test disasters"""
        disasters = []
        
        disaster_data = [
            {
                'name': 'Coastal Flood 2024',
                'disaster_type': 'flood',
                'severity': 'high',
                'status': 'active',
                'location': 'Coastal Region, City A',
                'latitude': Decimal('34.0522'),
                'longitude': Decimal('-118.2437'),
                'description': 'Severe flooding in coastal areas due to heavy rainfall and high tides.',
                'start_date': timezone.now() - timedelta(days=5),
                'estimated_damage': Decimal('5000000.00'),
                'affected_areas': 'Coastal Region, Beach Area, Downtown',
                'affected_population_estimate': 5000,
                'impact_radius_km': Decimal('25.50'),
                'impact_area_description': 'Affected area spans 25km radius including residential and commercial zones',
            },
            {
                'name': 'Mountain Earthquake',
                'disaster_type': 'earthquake',
                'severity': 'critical',
                'status': 'active',
                'location': 'Mountain Region, City B',
                'latitude': Decimal('37.7749'),
                'longitude': Decimal('-122.4194'),
                'description': 'Major earthquake with magnitude 7.2 affecting mountainous regions.',
                'start_date': timezone.now() - timedelta(days=3),
                'estimated_damage': Decimal('15000000.00'),
                'affected_areas': 'Mountain Villages, Highway 101, Rural Areas',
                'affected_population_estimate': 12000,
                'impact_radius_km': Decimal('50.00'),
                'impact_area_description': 'Widespread damage across 50km radius, multiple landslides reported',
            },
            {
                'name': 'Urban Fire Incident',
                'disaster_type': 'fire',
                'severity': 'medium',
                'status': 'contained',
                'location': 'Industrial District, City C',
                'latitude': Decimal('40.7128'),
                'longitude': Decimal('-74.0060'),
                'description': 'Large warehouse fire, now contained but cleanup ongoing.',
                'start_date': timezone.now() - timedelta(days=10),
                'end_date': timezone.now() - timedelta(days=1),
                'estimated_damage': Decimal('2000000.00'),
                'affected_areas': 'Industrial District',
                'affected_population_estimate': 500,
                'impact_radius_km': Decimal('5.00'),
                'impact_area_description': 'Fire contained within industrial zone',
            },
        ]

        for data in disaster_data:
            disaster, created = Disasters.objects.get_or_create(
                name=data['name'],
                defaults=data
            )
            disasters.append(disaster)

        return disasters

    def _create_resources(self):
        """Create test resources"""
        resources = []
        
        resource_data = [
            {'name': 'Rice', 'category': 'food', 'unit': 'kg', 'total_quantity': Decimal('5000.00'), 'available_quantity': Decimal('4500.00'), 'description': 'White rice in 1kg bags'},
            {'name': 'Bottled Water', 'category': 'water', 'unit': 'l', 'total_quantity': Decimal('10000.00'), 'available_quantity': Decimal('8500.00'), 'description': '1L bottled water'},
            {'name': 'First Aid Kits', 'category': 'medical', 'unit': 'box', 'total_quantity': Decimal('500.00'), 'available_quantity': Decimal('450.00'), 'description': 'Complete first aid kits'},
            {'name': 'Blankets', 'category': 'clothing', 'unit': 'piece', 'total_quantity': Decimal('2000.00'), 'available_quantity': Decimal('1800.00'), 'description': 'Warm blankets'},
            {'name': 'Tents', 'category': 'shelter', 'unit': 'unit', 'total_quantity': Decimal('300.00'), 'available_quantity': Decimal('250.00'), 'description': '4-person tents'},
            {'name': 'Hygiene Kits', 'category': 'hygiene', 'unit': 'pack', 'total_quantity': Decimal('1500.00'), 'available_quantity': Decimal('1200.00'), 'description': 'Personal hygiene kits'},
            {'name': 'Flashlights', 'category': 'equipment', 'unit': 'piece', 'total_quantity': Decimal('800.00'), 'available_quantity': Decimal('750.00'), 'description': 'LED flashlights with batteries'},
        ]

        for data in resource_data:
            resource, created = Resource.objects.get_or_create(
                name=data['name'],
                defaults=data
            )
            resources.append(resource)

        return resources

    def _create_camps(self, disasters, users):
        """Create test camps/shelters"""
        camps = []
        
        camp_data = [
            {
                'name': 'Emergency Shelter Alpha',
                'camp_type': 'shelter',
                'disasters': disasters[0],
                'location': 'City A Central Park',
                'latitude': Decimal('34.0522'),
                'longitude': Decimal('-118.2437'),
                'capacity': 500,
                'population_capacity': 450,
                'contact_person': 'John Smith',
                'contact_phone': '+1987654321',
                'email': 'shelteralpha@drms.local',
                'status': 'active',
                'coverage_radius_km': Decimal('10.00'),
                'service_area_description': 'Serving City A and surrounding suburbs',
            },
            {
                'name': 'Medical Camp Beta',
                'camp_type': 'medical',
                'disasters': disasters[1],
                'location': 'Mountain Region Hospital',
                'latitude': Decimal('37.7749'),
                'longitude': Decimal('-122.4194'),
                'capacity': 200,
                'population_capacity': 150,
                'contact_person': 'Dr. Jane Doe',
                'contact_phone': '+1987654322',
                'email': 'medicalbeta@drms.local',
                'status': 'active',
                'coverage_radius_km': Decimal('15.00'),
                'service_area_description': 'Providing medical care for earthquake victims',
            },
            {
                'name': 'Distribution Center Gamma',
                'camp_type': 'distribution',
                'disasters': disasters[0],
                'location': 'City A Warehouse District',
                'latitude': Decimal('34.0622'),
                'longitude': Decimal('-118.2537'),
                'capacity': 1000,
                'population_capacity': 800,
                'contact_person': 'Mike Johnson',
                'contact_phone': '+1987654323',
                'email': 'distributiongamma@drms.local',
                'status': 'active',
                'coverage_radius_km': Decimal('20.00'),
                'service_area_description': 'Resource distribution center',
            },
        ]

        for data in camp_data:
            camp, created = Camp.objects.get_or_create(
                name=data['name'],
                disasters=data['disasters'],
                defaults=data
            )
            camps.append(camp)

        return camps

    def _create_user_profiles(self, users, camps):
        """Create volunteer, victim, and camp admin profiles"""
        
        # Volunteers
        volunteer1 = Volunteer.objects.get_or_create(
            user=users['volunteer1'],
            defaults={
                'availability': True,
                'experience': '5 years of disaster relief experience, trained in first aid',
            }
        )[0]
        
        VolunteerSkill.objects.get_or_create(
            volunteer=volunteer1,
            skill='First Aid',
            defaults={'proficiency': 'expert'}
        )
        VolunteerSkill.objects.get_or_create(
            volunteer=volunteer1,
            skill='Search and Rescue',
            defaults={'proficiency': 'intermediate'}
        )

        volunteer2 = Volunteer.objects.get_or_create(
            user=users['volunteer2'],
            defaults={
                'availability': True,
                'experience': 'New volunteer, eager to help',
            }
        )[0]
        
        VolunteerSkill.objects.get_or_create(
            volunteer=volunteer2,
            skill='Food Distribution',
            defaults={'proficiency': 'beginner'}
        )

        # Victims
        Victim.objects.get_or_create(
            user=users['victim1'],
            defaults={
                'age': 35,
                'family_members': 3,
                'emergency_contact': '+1987654999',
                'special_needs': 'Wheelchair access required',
                'medical_conditions': 'Diabetes',
                'priority_level': 'high',
                'is_high_risk': True,
                'emergency_supplies_needed': 'Insulin, wheelchair, food',
            }
        )

        Victim.objects.get_or_create(
            user=users['victim2'],
            defaults={
                'age': 28,
                'family_members': 2,
                'emergency_contact': '+1987654998',
                'priority_level': 'medium',
                'is_high_risk': False,
            }
        )

        # Camp Admin
        if camps:
            CampAdmin.objects.get_or_create(
                user=users['camp_admin'],
                camp=camps[0],
            )

    def _create_donations(self, users, resources):
        """Create test donations"""
        donation1, created = Donation.objects.get_or_create(
            donor_name='ABC Corporation',
            defaults={
                'donor_type': 'organization',
                'contact_email': 'donations@abccorp.com',
                'contact_phone': '+1555123456',
                'created_by': users.get('donor'),
            }
        )
        
        if created and resources:
            DonationItem.objects.get_or_create(
                donation=donation1,
                resource=resources[0],  # Rice
                defaults={'quantity': Decimal('1000.00')}
            )
            DonationItem.objects.get_or_create(
                donation=donation1,
                resource=resources[1],  # Water
                defaults={'quantity': Decimal('2000.00')}
            )

        donation2, created = Donation.objects.get_or_create(
            donor_name='John Doe',
            defaults={
                'donor_type': 'individual',
                'contact_email': 'john@example.com',
                'contact_phone': '+1555765432',
                'created_by': users.get('donor'),
            }
        )
        
        if created and resources:
            DonationItem.objects.get_or_create(
                donation=donation2,
                resource=resources[3],  # Blankets
                defaults={'quantity': Decimal('50.00')}
            )

    def _create_alerts(self, disasters, users):
        """Create test alerts"""
        if disasters and users.get('admin'):
            Alert.objects.get_or_create(
                Disasters_id=disasters[0].id,  # Use Disasters_id for the foreign key
                title='Evacuation Warning - Coastal Area',
                defaults={
                    'Disasters': disasters[0],
                    'description': 'Immediate evacuation required for coastal areas. Flood waters rising rapidly.',
                    'severity': 'critical',
                    'status': 'active',
                }
            )
            
            Alert.objects.get_or_create(
                Disasters_id=disasters[1].id,
                title='Aftershock Warning',
                defaults={
                    'Disasters': disasters[1],
                    'description': 'Potential aftershocks expected in next 24 hours. Stay in safe areas.',
                    'severity': 'high',
                    'status': 'active',
                }
            )

    def _create_weather_alerts(self, users, disasters):
        """Create test weather alerts"""
        if users.get('admin') and disasters:
            WeatherAlert.objects.get_or_create(
                title='Heavy Rainfall Warning',
                defaults={
                    'weather_type': 'flood',
                    'risk_level': 'high',
                    'status': 'warning',
                    'location': 'Coastal Region',
                    'latitude': Decimal('34.0522'),
                    'longitude': Decimal('-118.2437'),
                    'description': 'Heavy rainfall expected in next 48 hours. Flash flood warning.',
                    'forecast_date': timezone.now() + timedelta(hours=24),
                    'expected_severity': 'high',
                    'affected_radius_km': Decimal('30.00'),
                    'rainfall_mm': Decimal('150.00'),
                    'issued_by': users['admin'],
                    'related_disaster': disasters[0],
                }
            )

    def _create_transport(self, camps):
        """Create test transport vehicles"""
        if camps:
            Transport.objects.get_or_create(
                vehicle_number='TRK-001',
                defaults={
                    'transport_type': 'truck',
                    'capacity': Decimal('5000.00'),
                    'status': 'available',
                    'current_location': 'Main Depot',
                    'assigned_to_camp': camps[0],
                }
            )
            
            Transport.objects.get_or_create(
                vehicle_number='VAN-002',
                defaults={
                    'transport_type': 'van',
                    'capacity': Decimal('1000.00'),
                    'status': 'in_use',
                    'current_location': 'En route to City A',
                    'assigned_to_camp': camps[0],
                }
            )

    def _create_help_requests(self, users, disasters):
        """Create test help requests"""
        if users.get('victim1') and disasters:
            help_req, created = HelpRequest.objects.get_or_create(
                victim=users['victim1'],
                disasters=disasters[0],
                description='Need immediate evacuation assistance. Family of 3 including elderly person.',
                defaults={
                    'location': '123 Coastal Street, City A',
                    'status': 'pending',
                }
            )
            
            if created and users.get('volunteer1'):
                TaskAssignment.objects.get_or_create(
                    volunteer=users['volunteer1'],
                    help_request=help_req,
                    defaults={
                        'task_description': 'Evacuate family from 123 Coastal Street',
                        'status': 'assigned',
                    }
                )

    def _create_resource_requests(self, camps, resources, users):
        """Create test resource requests"""
        if camps and resources and users.get('camp_admin'):
            ResourceRequest.objects.get_or_create(
                camp=camps[0],
                resource=resources[0],  # Rice
                defaults={
                    'quantity_requested': Decimal('500.00'),
                    'quantity_fulfilled': Decimal('0.00'),
                    'priority': 'high',
                    'status': 'pending',
                    'requested_by': users['camp_admin'],
                    'needed_by': timezone.now() + timedelta(days=2),
                    'reason': 'Food shortage at shelter. Need immediate supply.',
                }
            )

