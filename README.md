# Eyes
Eyes for iOS by Hefestru Fund  

## Compatible Devices

This app requires LiDAR scanner and is compatible with the following iPhone models:

- iPhone 12 Pro
- iPhone 12 Pro Max
- iPhone 13 Pro
- iPhone 13 Pro Max
- iPhone 14 Pro
- iPhone 14 Pro Max
- iPhone 15 Pro
- iPhone 15 Pro Max
- iPhone 16 Pro
- iPhone 16 Pro Max
- iPhone 17 Pro
- iPhone 17 Pro Max

![Project Reference Image](assets/example.jpeg)

## Demo Video

See the app in action: [Instagram Demo](https://www.instagram.com/p/DPppc_UDFv9?img_index=2)

## Project Description

**Eyes** is an iOS application that helps visually impaired individuals detect obstacles at different heights and distances using Apple’s built-in depth sensors.  
Through **real-time audio feedback**, the app provides an extra layer of awareness beyond the traditional white cane, reducing the risk of collisions with overhead or elevated objects.  

The project began with the idea of **manufacturing and donating physical devices**, but to accelerate development and reach users sooner, the first step is creating an iOS app. In the future, the vision includes designing and donating dedicated devices for broader accessibility.  

## Features

### Audio Feedback
The app provides real-time audio warnings when obstacles are detected in the detection zone. The Text-to-Speech system automatically announces obstacle distances in centimeters (e.g., "42" for 42 cm).

See `TextToSpeech.swift` for detailed usage examples and documentation.

## TO-DO

- [x] **Audio Feedback**  
  Real-time audio warnings for obstacle detection with distance announcement in centimeters.

- [ ] **AI-Powered Text Recognition**  
  Enable real-time reading of text from books, signs, product labels, and other everyday objects.

- [ ] **Object Recognition**  
  Train the system to identify and describe common items, such as:
  - Furniture (chairs, tables, sofas)
  - Household appliances (refrigerators, microwaves, washing machines)
  - Electronic devices (phones, computers, TVs)
  - Food items and packaging
  - Clothing and accessories
  - Transportation vehicles (cars, buses, bicycles)
  - Animals and pets
  - Plants and trees

- [ ] **Spatial Awareness Features**  
  Implement precise distance and direction detection to describe the relative position of objects.

- [x] **Energy Optimization**  
  Add an option to automatically turn off the screen during usage to save battery.

- [ ] **Navigation System with Map**  
  Implement an integrated navigation system with map functionality that provides audio-guided directions for visually impaired users. Features should include:
  - Real-time GPS-based navigation with voice announcements
  - Integration with AR depth sensing to avoid obstacles along the route
  - Audio feedback for turns, distance to destination, and route updates
  - Offline map support for areas with poor connectivity  

- [ ] **Startup optimization**