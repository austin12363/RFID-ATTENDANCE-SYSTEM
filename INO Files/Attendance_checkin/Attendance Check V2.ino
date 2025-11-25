#include <SPI.h>
#include <MFRC522.h>
#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <LiquidCrystal_I2C.h> // Include the LCD Library

// --- NEW PIN DEFINITIONS ---
// We moved these to free up 21 and 22 for the LCD
#define RST_PIN 4  
#define SS_PIN 5   
#define BUZZER 15

// --- LCD SETUP ---
// 0x27 is the common address. If it doesn't work, try 0x3F
int lcdColumns = 16;
int lcdRows = 2;
LiquidCrystal_I2C lcd(0x27, lcdColumns, lcdRows);  

MFRC522 mfrc522(SS_PIN, RST_PIN);
MFRC522::MIFARE_Key key;
MFRC522::StatusCode status;

int blockNum = 2;
byte bufferLen = 18;
byte readBlockData[18];

String card_holder_name;
const String sheet_url = "https://script.google.com/macros/s/AKfycbwupqyI6coqIsGY9jfU4_zfTNOCXoCH7K0mbKNxbWrysAIyORJn2ss4Y1EZhHFagyackw/exec?name=";

#define WIFI_SSID "ECE3GH"
#define WIFI_PASSWORD "12345678"

void setup() {
  Serial.begin(9600);
  
  // Initialize LCD
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Booting...");

  pinMode(BUZZER, OUTPUT);
  SPI.begin(); // Init SPI bus
  mfrc522.PCD_Init(); // Init MFRC522

  // WiFi Connection
  lcd.setCursor(0, 1);
  lcd.print("Connecting WiFi");
  Serial.println();
  Serial.print("Connecting to AP");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(200);
  }
  
  Serial.println("");
  Serial.println("WiFi connected.");
  Serial.println(WiFi.localIP());
  
  // Update LCD indicating readiness
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("System Ready");
  lcd.setCursor(0, 1);
  lcd.print("Scan ID Card");
}

void loop() {
  // Look for new cards
  if (!mfrc522.PICC_IsNewCardPresent()) { return; }
  if (!mfrc522.PICC_ReadCardSerial()) { return; }

  // LCD Feedback: Processing
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Reading Card...");

  Serial.println();
  Serial.println(F("Reading last data from RFID..."));
  ReadDataFromBlock(blockNum, readBlockData);

  Serial.println();
  Serial.print(F("Last data in RFID:"));
  Serial.print(blockNum);
  Serial.print(F(" --> "));
  
  // Prepare name for printing
  String nameRead = "";
  for (int j = 0; j < 16; j++) {
    Serial.write(readBlockData[j]);
    if(readBlockData[j] != 0) { // Construct string ignoring empty bytes
        nameRead += (char)readBlockData[j];
    }
  }
  Serial.println();
  
  // Show Name on LCD
  lcd.setCursor(0, 1);
  lcd.print(nameRead);

  // Beep Feedback
  digitalWrite(BUZZER, HIGH);
  delay(200);
  digitalWrite(BUZZER, LOW);

  if (WiFi.status() == WL_CONNECTED) {
    WiFiClientSecure client;
    client.setInsecure();
    card_holder_name = sheet_url + String((char*)readBlockData);
    card_holder_name.trim();
    Serial.println(card_holder_name);
    
    lcd.setCursor(0, 0);
    lcd.print("Sending Data...");
    
    HTTPClient https;
    Serial.print(F("[HTTPS] begin...\n"));

    if (https.begin(client, (String)card_holder_name)) {
      Serial.print(F("[HTTPS] GET...\n"));
      int httpCode = https.GET();

      if (httpCode = 302) {
        Serial.printf("[HTTPS] GET... code: %d\n", httpCode);
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Attendance done");
        lcd.setCursor(0, 1);
        lcd.print("Welcome");
        digitalWrite(BUZZER, HIGH);
        delay(150);
        digitalWrite(BUZZER, LOW);
        delay(400);
        digitalWrite(BUZZER, HIGH);
        delay(150);
        digitalWrite(BUZZER, LOW);
      } else {
        Serial.printf("[HTTPS] GET... failed, error: %s\n", https.errorToString(httpCode).c_str());
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Send Failed");
        digitalWrite(BUZZER, HIGH);
        delay(300);
        digitalWrite(BUZZER, LOW);
        delay(200);
        digitalWrite(BUZZER, HIGH);
        delay(300);
        digitalWrite(BUZZER, LOW);
        delay(200);
        digitalWrite(BUZZER, HIGH);
        delay(300);
        digitalWrite(BUZZER, LOW);
        delay(200);
      }
      https.end();
      delay(1500); // Wait so user can read the message
    } else {
      Serial.printf("[HTTPS] Unable to connect\n");
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Conn. Error");
    }
  }
  
  // Reset LCD to ready state
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("System Ready");
  lcd.setCursor(0, 1);
  lcd.print("Scan ID Card");
  
  // Halt PICC
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}


void ReadDataFromBlock(int blockNum, byte readBlockData[]) {
  for (byte i = 0; i < 6; i++) {
    key.keyByte[i] = 0xFF;
  }
  status = mfrc522.PCD_Authenticate(MFRC522::PICC_CMD_MF_AUTH_KEY_A, blockNum, &key, &(mfrc522.uid));
  if (status != MFRC522::STATUS_OK) {
    Serial.print("Authentication failed for Read: ");
    Serial.println(mfrc522.GetStatusCodeName(status));
    lcd.clear();
    lcd.print("Auth Failed");
    return;
  } else {
    Serial.println("Authentication success");
  }
  status = mfrc522.MIFARE_Read(blockNum, readBlockData, &bufferLen);
  if (status != MFRC522::STATUS_OK) {
    Serial.print("Reading failed: ");
    Serial.println(mfrc522.GetStatusCodeName(status));
    lcd.clear();
    lcd.print("Read Failed");
    return;
  } else {
    Serial.println("Block was read successfully");
  }
}
