# Zikrim Premium System & Rabia Memory

## Premium System

### Subscriptions
- [x] Monthly: 79.9 TRY
- [x] Yearly: 799.9 TRY with "En Popüler" badge

### Premium Features
- [x] Unlimited Rabia AI conversations (free users: 3/day)
- [x] Ad-free experience (banner + interstitial hidden)
- [x] Premium Dhikr Packs (Sabır, Şükür, Sabah Rutinleri, Uyku Öncesi)
- [x] Premium Themes (Night Mosque, Minimal Gold, Dark Spiritual)
- [x] Personalized dhikr recommendations via Rabia

### Paywall
- [x] Modern conversion-optimized paywall with MeshGradient header
- [x] Feature list with animated rows
- [x] Pricing cards with yearly pre-selected
- [x] "Premium'a Geç" CTA button
- [x] Restore purchases via RevenueCat
- [x] Privacy Policy and Terms of Use links in footer

### Rabia Limit Paywall
- [x] Dedicated sheet when daily limit reached
- [x] Shows Rabia avatar, message, and upgrade CTA

### Behavioral Changes
- [x] Save button in Manevi Akış no longer triggers Rabia suggestions
- [x] Premium dhikr packs locked with lock icon in ListelerView
- [x] Theme picker in Daha Fazla settings

## Rabia Memory System

### Features
- [x] Rabia remembers name, city, favorite dhikr, last mood
- [x] Personalized responses using memory context
- [x] Enhanced Istanbul Turkish conversational style
- [x] Memory stored locally via UserDefaults

### Files
- [x] RabiaMemory.swift — data model
- [x] RabiaMemoryService.swift — persistence
- [x] RabiaPromptBuilder.swift — system prompt builder

## Daily Dhikr Streak System

### Features
- [x] Track consecutive days of dhikr completion
- [x] Streak card UI with flame icon in Tesbihat screen
- [x] Milestone messages (7, 30, 90 days)
- [x] Streak resets if a day is skipped
- [x] Records on session completion only

### Files
- [x] DhikrStreakService.swift — streak tracking via UserDefaults
- [x] CounterView.swift — streak card UI
- [x] CounterViewModel.swift — triggers recordDhikrSession on completion

## Test Scenarios
- [ ] Guest user app açar -> premium false
- [ ] Guest user paywall görür -> premium özellikler kilitli
- [ ] Login + active entitlement -> premium true
- [ ] Logout -> premium hemen false
- [ ] App relaunch after logout -> premium false
- [ ] Localization key missing olduğunda ham key görünmez
