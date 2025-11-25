ECE 3GH



### Component Connection Table

| Component | Component Pin | ESP32 Pin | Function / Note |
| :--- | :--- | :--- | :--- |
| **I2C LCD** | SDA | GPIO 21 | I2C Data (Fixed) |
| | SCL | GPIO 22 | I2C Clock (Fixed) |
| | VCC | VIN (5V) | Power (5V required for clear text) |
| | GND | GND | Ground |
| | | | |
| **RFID-RC522** | SDA (SS) | GPIO 5 | **Changed from 21** (Chip Select) |
| | RST | GPIO 4 | **Changed from 22** (Reset) |
| | SCK | GPIO 18 | SPI Clock |
| | MOSI | GPIO 23 | SPI Data In |
| | MISO | GPIO 19 | SPI Data Out |
| | 3.3V | 3V3 | **WARNING: Do NOT use 5V** |
| | GND | GND | Ground |
| | IRQ | (Not Connected)| |
| | | | |
| **Buzzer** | Signal(I/O) | GPIO 15 |  |
| | Negative (-) | GND | Ground |
| | Positive (+) | 3.3V | Positive |
