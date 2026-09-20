//+------------------------------------------------------------------+
//| DGN_License.mqh                                                   |
//| Supabase tabanli lisans dogrulama modulu - DGN Nexus Pro R21      |
//|                                                                    |
//| Kullanim:                                                         |
//|  1) Bu dosyayi ana .mq5 ile AYNI klasore koy (Experts altina)     |
//|  2) Ana dosyanin en ustune: #include "DGN_License.mqh"            |
//|  3) OnInit() sonunda, return INIT_SUCCEEDED'dan hemen once:       |
//|        License_Check(true);                                       |
//|  4) OnTick()'in EN BASINA (ilk satir):                             |
//|        if(!License_IsValid()) { Panel_RequestUpdate(false); return; } |
//|  5) OnTimer() icine bir satir ekle:                                |
//|        License_MaybeRecheck();                                    |
//|                                                                    |
//| NOT: MetaTrader "WebRequest icin izin verilen URL listesi"ne       |
//| asagidaki LICENSE_SUPABASE_URL host'unu eklemeden bu modul         |
//| CALISMAZ (hata 4014 basar, log'da aciklama cikar).                 |
//| Araclar > Secenekler > Uzman Danismanlar sekmesinden ekleyin.      |
//+------------------------------------------------------------------+
#property strict

input group "=== LICENSE / LISANS ==="
input string InpLicenseKey = "";   // Lisans anahtarinizi buraya girin

//--- Kendi projenizin degerleri (panel ile ayni Supabase projesi) ---
#define LICENSE_SUPABASE_URL   "https://ehmxoqvqjehbtoihwtna.supabase.co/functions/v1/license-verify"
#define LICENSE_ANON_KEY       "sb_publishable_XLbXc4E9ISqAmNlB_46lzQ_V9NctW38"
#define LICENSE_EA_VERSION     "1.78.50"
#define LICENSE_RECHECK_SEC    21600     // 6 saatte bir yeniden dogrula
#define LICENSE_GRACE_SEC      172800    // Sunucuya ulasilamazsa 48 saat tolerans (internet/broker kesintisi icin)

bool     g_lic_valid         = false;
bool     g_lic_checkedOnce   = false;
bool     g_lic_stateLoaded   = false;
datetime g_lic_lastGoodCheck = 0;
datetime g_lic_lastAttempt   = 0;
string   g_lic_lastReason    = "NOT_CHECKED";

//+------------------------------------------------------------------+
//| Son bilinen durum (valid + son basarili kontrol zamani) diske      |
//| yazilir/okunur. Bu olmadan EA her yeniden baslatildiginda          |
//| g_lic_lastGoodCheck 0'a doner ve "grace suresi" restart sonrasi    |
//| HICBIR ZAMAN devreye giremezdi (bellekte tutulan deger EA         |
//| kapaninca kayboluyordu) — kapatip acinca lisansin aninda           |
//| gecersiz gorunmesinin sebebi buydu.                                |
//+------------------------------------------------------------------+
void License_LoadStateOnce() {
   if(g_lic_stateLoaded) return;
   g_lic_stateLoaded = true;
   int h = FileOpen("dgn_license_state.dat", FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h == INVALID_HANDLE) return;
   string line1 = FileReadString(h); // son basarili kontrol (unix ts)
   string line2 = FileReadString(h); // "1" = valid, "0" = invalid
   FileClose(h);
   long ts = StringToInteger(line1);
   if(ts > 0) g_lic_lastGoodCheck = (datetime)ts;
   g_lic_valid = (line2 == "1");
}

void License_SaveState() {
   int h = FileOpen("dgn_license_state.dat", FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h == INVALID_HANDLE) return;
   FileWriteString(h, (string)(long)g_lic_lastGoodCheck + "\n");
   FileWriteString(h, g_lic_valid ? "1" : "0");
   FileClose(h);
}

//+------------------------------------------------------------------+
//| Cihaz jetonu: MQL5'te gercek donanim kimligi yok. Ilk calistirmada|
//| rastgele bir token uretilip MQL5\Files\Common altina yaziliyor,   |
//| sonraki calistirmalarda ayni terminalde okunuyor (terminal-bazli  |
//| kimlik - format degistirilirse/silinirse yeni token uretilir).    |
//+------------------------------------------------------------------+
string License_DeviceToken() {
   string fname = "dgn_device_token.dat";
   int h = FileOpen(fname, FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h != INVALID_HANDLE) {
      string tok = FileReadString(h);
      FileClose(h);
      if(StringLen(tok) >= 16) return tok;
   }
   MathSrand((int)GetTickCount() ^ (int)TimeLocal());
   string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
   string tok = "";
   for(int i = 0; i < 32; i++)
      tok += StringSubstr(chars, MathRand() % StringLen(chars), 1);
   int hw = FileOpen(fname, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(hw != INVALID_HANDLE) { FileWriteString(hw, tok); FileClose(hw); }
   return tok;
}

//+------------------------------------------------------------------+
//| Basit JSON deger okuyucu — sadece duz {"key":"val" / true / 123}  |
//| seklindeki cevaplar icin yeterli, tam JSON parser degil.          |
//+------------------------------------------------------------------+
string License_JsonGet(const string json, const string key) {
   string pat = "\"" + key + "\"";
   int p = StringFind(json, pat);
   if(p < 0) return "";
   p = StringFind(json, ":", p);
   if(p < 0) return "";
   p++;
   while(p < StringLen(json) && StringGetCharacter(json, p) == ' ') p++;
   if(p >= StringLen(json)) return "";
   if(StringGetCharacter(json, p) == '"') {
      int start = p + 1;
      int e = StringFind(json, "\"", start);
      if(e < 0) return "";
      return StringSubstr(json, start, e - start);
   }
   int start = p, e = start;
   while(e < StringLen(json)) {
      ushort c = StringGetCharacter(json, e);
      if(c == ',' || c == '}') break;
      e++;
   }
   return StringSubstr(json, start, e - start);
}

//+------------------------------------------------------------------+
//| Sunucuya sorar. verbose=true ise sonucu Print eder (OnInit icin). |
//| Donen deger: lisans su an gecerli mi (trade atilabilir mi).      |
//+------------------------------------------------------------------+
bool License_Check(bool verbose) {
   // v1.78.72 FIX: Strategy Tester'da WebRequest guvenilir calismiyor (izinli
   // URL listesi Tester'da farkli/yok sayilabiliyor) ve ilk calistirmada
   // g_lic_lastGoodCheck==0 oldugu icin asagidaki grace-period de devreye
   // giremiyordu -> backtest/optimizasyonda EA hep "lisans gecersiz" kalip
   // OnTick() trade pipeline'ina hic girmiyordu (0 islem). Tester ortaminda
   // lisans kontrolunu tamamen atla; gercek hesapta (demo/canli) davranis
   // degismez.
   if(MQLInfoInteger(MQL_TESTER)) {
      g_lic_valid       = true;
      g_lic_checkedOnce = true;
      g_lic_lastReason  = "TESTER_BYPASS";
      g_lic_lastGoodCheck = TimeCurrent();
      g_lic_lastAttempt   = TimeCurrent();
      if(verbose) Print("LISANS: Strategy Tester tespit edildi, lisans kontrolu atlaniyor (backtest/optimizasyon).");
      return true;
   }

   License_LoadStateOnce();
   g_lic_lastAttempt = TimeCurrent();

   if(StringLen(InpLicenseKey) < 4) {
      g_lic_valid = false;
      g_lic_lastReason = "LICENSE_KEY_EMPTY";
      License_SaveState();
      if(verbose) Print("LISANS: Anahtar girilmemis (InpLicenseKey bos). EA trade ATMAYACAK.");
      return false;
   }

   string url  = LICENSE_SUPABASE_URL;
   string body = StringFormat(
      "{\"license_key\":\"%s\",\"account_number\":%I64d,\"broker\":\"%s\",\"server_name\":\"%s\",\"ea_version\":\"%s\",\"device_id\":\"%s\"}",
      InpLicenseKey,
      AccountInfoInteger(ACCOUNT_LOGIN),
      AccountInfoString(ACCOUNT_COMPANY),
      AccountInfoString(ACCOUNT_SERVER),
      LICENSE_EA_VERSION,
      License_DeviceToken()
   );

   string headers = "Content-Type: application/json\r\napikey: " + LICENSE_ANON_KEY + "\r\n";
   char   post[], result[];
   string resultHeaders;
   StringToCharArray(body, post, 0, StringLen(body));

   ResetLastError();
   int res = WebRequest("POST", url, headers, 5000, post, result, resultHeaders);

   if(res == -1) {
      int err = GetLastError();
      if(err == 4014)
         Print("LISANS HATASI: WebRequest izinli degil. Araclar > Secenekler > Uzman Danismanlar > "
               "'WebRequest icin izin verilen URL listesi' kismina ekleyin: ", url);
      else
         Print("LISANS: Sunucuya ulasilamadi, hata=", err);

      // Ag hatasi: son basarili kontrolden beri grace suresi dolmadiysa eski durumu koru
      if(g_lic_lastGoodCheck > 0 && (TimeCurrent() - g_lic_lastGoodCheck) < LICENSE_GRACE_SEC) {
         if(verbose) Print("LISANS: Sunucuya ulasilamadi ama grace suresi icinde, mevcut durum korunuyor (valid=",
                            g_lic_valid ? "EVET" : "HAYIR", ").");
         return g_lic_valid;
      }
      g_lic_valid = false;
      g_lic_lastReason = "NETWORK_ERROR";
      License_SaveState();
      return false;
   }

   string resp = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   bool ok = (License_JsonGet(resp, "valid") == "true");
   string reason = License_JsonGet(resp, "reason");

   g_lic_valid       = ok;
   g_lic_lastReason  = (reason == "") ? (ok ? "OK" : "UNKNOWN") : reason;
   g_lic_checkedOnce = true;
   if(ok) g_lic_lastGoodCheck = TimeCurrent();
   License_SaveState();

   if(verbose || !ok)
      PrintFormat("LISANS: valid=%s reason=%s", ok ? "EVET" : "HAYIR", g_lic_lastReason);

   return ok;
}

bool License_IsValid() { return g_lic_valid; }

//+------------------------------------------------------------------+
//| OnTimer() icinden her tikte cagir — kendi icinde throttle var,    |
//| gercek istek sadece LICENSE_RECHECK_SEC'te bir gider.             |
//+------------------------------------------------------------------+
void License_MaybeRecheck() {
   if(TimeCurrent() - g_lic_lastAttempt >= LICENSE_RECHECK_SEC)
      License_Check(false);
}
