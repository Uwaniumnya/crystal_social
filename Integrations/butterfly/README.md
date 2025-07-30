# Butterfly Collection System - SQL Integration

This folder contains the complete SQL integration for the Crystal Social butterfly collection system. The butterfly feature allows users to discover, collect, and organize a diverse ecosystem of butterfly species with varying rarities and special traits.

## 📁 File Structure

### 01_butterfly_core.sql
**Core System Foundation**
- Primary tables: `butterfly_species`, `butterfly_album`, `butterfly_discoveries`
- User progress tracking: `butterfly_user_stats`, `butterfly_user_preferences`
- Discovery mechanics with cooldowns and success tracking
- Collection progress and milestone system
- Favorites management with heart counts
- RLS policies for data security

### 02_butterfly_species_data.sql
**Species Data & Game Mechanics**
- Comprehensive species database (90 butterflies)
- Rarity system: Common → Uncommon → Rare → Epic → Legendary → Mythical
- Habitat system with environmental bonuses
- Reward structures for discoveries
- Seasonal discovery modifiers
- Weather effect system
- Trading capabilities
- Advanced filtering and search functions

### 03_butterfly_events.sql
**Events & Social Features**
- Special discovery events and challenges
- Daily/weekly quests system
- Leaderboards and achievements
- Social features (sharing, competitions)
- Event rewards and progression
- Quest tracking and completion
- Community challenges

### 04_butterfly_analytics.sql
**Analytics & Performance**
- User behavior tracking and analytics
- Performance monitoring and optimization
- Caching system for improved response times
- A/B testing framework
- Error logging and monitoring
- Feature usage tracking
- Recommendation engine
- Data cleanup and maintenance

### 05_butterfly_setup.sql
**System Configuration & Maintenance**
- System configuration management
- Automated maintenance tasks
- Health monitoring and status checks
- User initialization procedures
- Integration with main profile system
- Discovery probability calculations
- Weather and seasonal effect management
- Administrative tools and functions

## 🎮 Core Features

### Discovery System
- **Cooldown Mechanics**: 15-minute cooldown between discovery attempts
- **Success Rates**: Probability-based discovery with species rarity modifiers
- **Daily Limits**: Maximum 10 discoveries per day per user
- **Environmental Effects**: Weather and seasonal bonuses affect discovery rates

### Collection Management
- **Album System**: Personal collection tracking with discovery timestamps
- **Favorites**: Heart-based favorite system with social features
- **Progress Tracking**: Level progression based on discoveries
- **Milestones**: Achievement system for collection completions

### Rarity System
| Rarity | Base Discovery Rate | Special Effects |
|--------|-------------------|-----------------|
| Common | 40% | Standard butterflies, good for beginners |
| Uncommon | 25% | Slightly enhanced visual effects |
| Rare | 15% | Beautiful animations and sounds |
| Epic | 8% | Spectacular visual effects |
| Legendary | 2% | Legendary status with unique abilities |
| Mythical | 0.5% | Extremely rare with magical properties |

### Habitat System
- **Garden**: Common butterflies (20% discovery bonus)
- **Forest**: Mixed rarities with nature theme
- **Meadow**: Uncommon and rare species
- **Mountain**: Epic and legendary butterflies
- **Mystical Grove**: Mythical butterfly sanctuary
- **Seasonal Areas**: Rotating habitats with special bonuses

## 🔧 Integration Points

### Flutter Integration
The SQL schema integrates with existing Flutter code:
- `butterfly_garden_screen.dart` - Main collection interface
- `butterfly_exports.dart` - Data export functionality
- Database table names match existing Dart implementations
- Supports existing UI components and user flows

### Profile System Integration
- Extends `profiles` table with butterfly-specific preferences
- Notification settings for discovery alerts
- Tutorial completion tracking
- Feature enable/disable flags

### Admin Integration
- Administrative oversight through existing admin system
- Event management and configuration
- User statistics and analytics
- Content moderation capabilities

## 🚀 Setup Instructions

1. **Database Setup**: Run files in numerical order (01-05)
2. **Configuration**: Adjust settings in `butterfly_system_config` table
3. **Species Import**: All 90 butterfly species are automatically imported
4. **User Initialization**: New users are automatically initialized via trigger
5. **Maintenance**: Automated tasks handle cleanup and optimization

## 📊 Performance Features

### Caching System
- Smart caching for frequently accessed data
- Cache invalidation strategies
- Performance monitoring and metrics

### Optimization
- Comprehensive indexing strategy
- Query optimization for large datasets
- Efficient pagination and filtering
- Background maintenance procedures

### Analytics
- Real-time user behavior tracking
- Discovery pattern analysis
- Feature usage statistics
- Performance monitoring dashboards

## 🛠 Maintenance

### Automated Tasks
- **Daily Analytics**: User statistics and progress updates
- **Cache Cleanup**: Expired cache entry removal (every 6 hours)
- **Weekly Statistics**: Comprehensive system metrics
- **Monthly Cleanup**: Old data archival and cleanup
- **Recommendations**: Daily personalized suggestions

### Health Monitoring
- System status checks
- Error rate monitoring
- Performance metrics tracking
- Automated alerting for issues

## 🔐 Security Features

### Row Level Security (RLS)
- User data isolation
- Admin-only access to sensitive tables
- Public configuration visibility control

### Data Protection
- User preference privacy
- Discovery history protection
- Social feature security
- Admin audit trails

## 🎯 Configuration Options

Key system settings available in `butterfly_system_config`:
- Discovery cooldown periods
- Daily discovery limits
- Success rate modifiers
- Feature toggles (trading, weather effects, etc.)
- Notification preferences
- Cache durations
- Maintenance schedules

## 🌟 Advanced Features

### Recommendation Engine
- Personalized butterfly suggestions
- Discovery pattern analysis
- Habitat recommendations
- Optimal discovery timing

### Social Features
- Favorite sharing and hearts
- Discovery celebrations
- Community challenges
- Leaderboards and rankings

### Event System
- Special discovery events
- Seasonal celebrations
- Limited-time butterflies
- Community goals and rewards

This comprehensive SQL integration provides a robust foundation for the butterfly collection system, supporting all current Flutter functionality while enabling future feature expansion and optimization.
