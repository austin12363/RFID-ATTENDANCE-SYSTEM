#include <SPI.h>
#include <MFRC522.h>
#include <LiquidCrystal_I2C.h>

// --- PINS (Using your new wiring) ---
#define RST_PIN 4  
#define SS_PIN 5   
#define BUZZER 15

// --- LCD SETUP ---
LiquidCrystal_I2C lcd(0x27, 16, 2); 

MFRC522 mfrc522(SS_PIN, RST_PIN);
MFRC522::MIFARE_Key key;
MFRC522::StatusCode status;

// --- CONFIGURATION ---
int blockNum = 4; // Writing to User Block 4

// ******************************************************
// CHANGE THE NAME HERE FOR EACH NEW CARD:
// (Max 16 chars. Use underscores, no spaces preferrably)
byte blockData[16] = { "Nat_Mendoza" }; 
// ******************************************************

byte bufferLen = 18;
byte readBlockData[18];

void setup() {
  Serial.begin(9600);
  
  // Init Hardware
  pinMode(BUZZER, OUTPUT);
  lcd.init();
  lcd.backlight();
  
  SPI.begin();
  mfrc522.PCD_Init();

  Serial.println("Writer Mode Ready");
  
  // Show "Ready" on LCD
  lcd.setCursor(0, 0);
  lcd.print("WRITER MODE");
  lcd.setCursor(0, 1);
  lcd.print("Scan to Write...");
}

void loop() {
  // Prepare Key
  for (byte i = 0; i < 6; i++) { key.keyByte[i] = 0xFF; }

  // 1. Look for card
  if (!mfrc522.PICC_IsNewCardPresent()) { return; }
  if (!mfrc522.PICC_ReadCardSerial()) { return; }

  // 2. Feedback: "Writing..."
  Serial.println("**Card Detected**");
  lcd.clear();
  lcd.print("Writing Name...");
  lcd.setCursor(0, 1);
  // Print the name we are trying to write
  for(int i=0; i<16; i++) { 
    if(blockData[i] != 0) lcd.print((char)blockData[i]); 
  }

  // 3. Write Data
  WriteDataToBlock(blockNum, blockData);
  
  // 4. Read Data back to verify
  ReadDataFromBlock(blockNum, readBlockData);

  // 5. Verify Success
  // We compare the first character of what we wrote vs what we read
  if (readBlockData[0] == blockData[0]) {
      lcd.clear();
      lcd.print("WRITE SUCCESS!");
      lcd.setCursor(0, 1);
      lcd.print("Remove Card");
      playSuccess();
  } else {
      lcd.clear();
      lcd.print("WRITE FAILED");
      playError();
  }

  // Halt to prevent re-writing constantly
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
  
  delay(2000); // Wait 2 seconds before ready for next card
  
  // Reset LCD to Ready
  lcd.clear();
  lcd.print("WRITER MODE");
  lcd.setCursor(0, 1);
  lcd.print("Scan Next Card");
}

// --- FUNCTIONS ---

void WriteDataToBlock(int blockNum, byte blockData[]) {
  // Authenticate
  status = mfrc522.PCD_Authenticate(MFRC522::PICC_CMD_MF_AUTH_KEY_A, blockNum, &key, &(mfrc522.uid));
  if (status != MFRC522::STATUS_OK) {
    Serial.print("Auth Error: "); Serial.println(mfrc522.GetStatusCodeName(status));
    return;
  }
  
  // Write
  status = mfrc522.MIFARE_Write(blockNum, blockData, 16);
  if (status != MFRC522::STATUS_OK) {
    Serial.print("Write Error: "); Serial.println(mfrc522.GetStatusCodeName(status));
    return;
  }
}

void ReadDataFromBlock(int blockNum, byte readBlockData[]) {
  status = mfrc522.PCD_Authenticate(MFRC522::PICC_CMD_MF_AUTH_KEY_A, blockNum, &key, &(mfrc522.uid));
  if (status != MFRC522::STATUS_OK) {
    return; // Error handled by comparison check in loop
  }
  status = mfrc522.MIFARE_Read(blockNum, readBlockData, &bufferLen);
}

// --- BUZZER TUNES ---

void playSuccess() {
  // Happy "Ding-Ding"
  digitalWrite(BUZZER, HIGH); delay(100);
  digitalWrite(BUZZER, LOW);  delay(50);
  digitalWrite(BUZZER, HIGH); delay(100);
  digitalWrite(BUZZER, LOW);
}

void playError() {
  // Long Warning Beep
  digitalWrite(BUZZER, HIGH); delay(500);
  digitalWrite(BUZZER, LOW);
}
