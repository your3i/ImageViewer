# ImageViewer
This is a demo project of an image viewer with the "Photos" app like transitions.

## Demo
#### Screen #1
Three thumnail images are listed.

#### Screen #2
Preview images (original images are loaded lazily), zoom in/out, tap to dismiss or swift to dismiss interactively.


![alt text](https://i.gyazo.com/2bde4765de943f7315363ffcdc40765d.gif?_ga=2.42030124.807690052.1543200206-1452481341.1542244821)

## Features
- [x] load one or more images
  - [x] scroll to view other images
  - [ ] ~~show page control(not yet and no plan)~~
- [x] open
  - [x] open and start viewing from the tapped image
- [x] dismiss
  - [x] one tap to dismiss
  - [x] swipe up/down to dismiss
    - [x] interactive
    - [x] with dimming view changes
- [x] load original images
  - [x] show thumbnail images first and load original images lazily
- [x] zoom in/out
  - [x] pinch to zoom
  - [x] double tap to toggle zoom
