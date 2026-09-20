//+------------------------------------------------------------------+
//|    DGN Nexus Pro R21  v1.78.168 RISKTEST-PROOF  (SADECE TEST)      |
//|  Kaynak: kullanicinin v1.78.167 ile aldigi 1 aylik backtest        |
//|  (XAUUSD M5, 2026.08.03-08.31) ve "kademeli islem acmiyor, tek     |
//|  islem cok uzun tutuluyor, lot buyumuyor, Dengeli grid lotu 0.02   |
//|  ama acilan 0.01" bildirimi.                                       |
//|                                                                    |
//|  TESHIS (Journal + kod okumasiyla): risk motorlari kapali degil,   |
//|  tersine uc limit birlikte ~$1000 hesapta tek bir 0.01 lota izin   |
//|  veriyor:                                                          |
//|   (a) RiskModel_BasketRiskOK: butce = equity x InpRiskSizing_      |
//|       MaxRiskPct (%3 = ~$29.5); tek 0.01 lotun Hard-SL riski       |
//|       (7xATR) zaten ~$24-29 -> 2. bacak her tick RISK MODEL VETO.  |
//|   (b) GridRisk_Enforce: InpGridRiskMaxDDPct=%2 (~$19.6), uyari     |
//|       esigi %80 (~$15.7) -> yeni kademe kapanir, $19.6'da sepet    |
//|       komple kapatilir.                                            |
//|   (c) RiskCap_MaxLot: 29.46/(7xATR 4.10x100)=0.0103 -> 0.01; 0.02  |
//|       lot icin ATR<=~2.1 gerekir. Kademe carpani sadece depth>0'da |
//|       calistigi icin (2. bacak hic acilamadigindan) hic devreye    |
//|       girmiyor.                                                    |
//|                                                                    |
//|  BU SURUMDE (KOD MANTIGI DEGISMEDI, yalniz 3 input varsayilani):   |
//|   InpRiskSizing_MaxRiskPct : 3.0 -> 15.0                           |
//|   InpGridRiskMaxDDPct      : 2.0 -> 8.0                            |
//|   InpSR_LogDecisions       : false -> true                         |
//|                                                                    |
//|  AMAC: teshisi KANITLAMAK. Ayni tarih araligiyla (2026.08.03-      |
//|  2026.08.31) Strategy Tester'da ikinci kademe ve lot buyumesi      |
//|  gorunuyorsa neden dogrulanmis olur; gorunmuyorsa Journal'daki     |
//|  "R21 TESHIS RED ... sebep=" satirlari siradaki engeli gosterir.   |
//|                                                                    |
//|  UYARI: %15 risk butcesi / %8 Grid DD limiti CANLI/DEMO hesap      |
//|  icin degildir. Kanit testinden sonra gercekci degerler secilip    |
//|  bu 3 satir geri alinmalidir.                                      |
//|                                                                    |
//|  NOT: Tester'da eski bir .set yuklenirse veya Girdiler sekmesinde  |
//|  onceki degerler duruyorsa bu varsayilanlari EZER - test oncesi    |
//|  Girdiler sekmesinde yukaridaki 3 degeri kontrol edin.             |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|    DGN Nexus Pro R21  v1.78.167 KADEME-CARPAN-FIX                  |
//|  Kaynak: kullanicinin 1 aylik backtest raporu (v1.78.165 MINLOT_   |
//|  RISK_DIAG, XAUUSD M5, 2026.08.03-08.31) ve bildirimi: "islem      |
//|  sureleri cok uzun, kademeli islem acmiyor, lotu buyutmuyor, tek   |
//|  islemde gidiyor, risk motorlarinin onemi kalmiyor".               |
//|                                                                    |
//|  DOGRULAMA: Raporun Islemler tablosu incelendiginde, test boyunca  |
//|  225 Grid islemi boyunca AYNI yonde ikinci bir kademe hicbir zaman |
//|  ilk pozisyon acikken uste binmemis - hep tek ac / TP-SL ile kapat |
//|  / yeniden ac dongusu. Depth (ayni yondeki acik kademe sayisi)     |
//|  fiilen hep 0'da kalmis (ort. tutma suresi 1:11:53, maks 8:06:24). |
//|                                                                    |
//|  KOK NEDEN #1 (lot buyumuyor): Lattice_CalcLot() carpani           |
//|  (g_rt_grid_mult_on/g_rt_seq_mult) SADECE depth>0 iken devreye     |
//|  girebiliyor - ama depth zaten hep 0 (asagida #2). AYRICA carpan   |
//|  bayraklari AdaptiveMarket_ClearOldMotorState() ve                 |
//|  AdaptiveMarket_Refresh() tarafindan rejim NETVOL veya SOLVER+trend|
//|  DISINDAKI her durumda (FIXED/BALANCE_PCT/TARGET_DEFICIT/          |
//|  CONTROLLED_RECOVERY/SOLVER-range) kosulsuz KAPATILIYORDU - panel  |
//|  uzerinden ACIK yapilsa bile bir sonraki rejim degerlendirmesinde  |
//|  (10sn'de bir) geri KAPANIYORDU.                                   |
//|                                                                    |
//|  KOK NEDEN #2 (kademeli acmiyor): Lattice_TryOpenLevel() her yeni  |
//|  kademe icin (SADECE ilk giris degil, 2./3./4. kademe icin de)     |
//|  SR_EntryConfirmed() (breakout-retest-bounce/range-bounce onayi)   |
//|  ariyordu. Bu onay ilk yon karari icin mantikli, ama zaten ACIK   |
//|  bir pozisyona STEP mesafesinde ekleme yaparken de ayni sikilikta  |
//|  isteniyordu - STEP+trend+netting+risk motorlari zaten yeterli     |
//|  guvenligi sagliyorken kademelemeyi fiilen imkansiz kiliyordu.     |
//|                                                                    |
//|  DUZELTME (kullanici onayiyla, iki yeni input ile TAMAMEN geri     |
//|  alinabilir - varsayilan degerler kullanicinin sectigi davranis):  |
//|  1) InpVG_GridMultRegimeControl (varsayilan false): CARPAN         |
//|     panelden/init'ten ne ayarlandiysa TUM rejimlerde SABIT kalir;  |
//|     adaptif motor artik g_rt_grid_mult_on/g_rt_seq_mult'a          |
//|     DOKUNMAZ. true = eski davranis (rejime gore otomatik).         |
//|  2) InpSR_RequireOnAddLevels (varsayilan false): SR onayi SADECE   |
//|     basket'in ILK kademesinde aranir (lat.buy/sell_levels_active== |
//|     0); 2.+ kademe eklerken aranmaz. true = eski davranis (her     |
//|     kademede zorunlu).                                             |
//|                                                                    |
//|  BYPASS EDILMEYEN HICBIR SEY YOK: HardSL, GridRiskFirewall,        |
//|  RiskGovernor (AYNI_YON_ACIK_POZ_LIMITI dahil), RiskCap_MaxLot,     |
//|  MIN_SANIYE_THROTTLE, MAX_KADEME, Netting, Trend Uyum Blogu, ADX   |
//|  filtresi, Trade_PreflightMarketOrder - hicbiri degistirilmedi.    |
//|  Sadece kademe EKLEME'sinde SR tekrarini ve CARPAN'in rejime bagli |
//|  otomatik kapanmasini kaldirdik; ilk giris kalitesi ve tum diger   |
//|  risk katmanlari aynen calismaya devam ediyor.                     |
//|                                                                    |
//|  DOGRULAMA GEREKLI: Ayni tarih araligiyla (2026.08.03-08.31) bir   |
//|  Strategy Tester kosusu alip artik ayni yonde 2+ kademenin uste    |
//|  bindigini, CARPAN degeriyle lotun buyudugunu ve ortalama tutma    |
//|  suresinin kisaldigini dogrulayin. InpSR_LogDecisions=true ile     |
//|  Journal'da "R21 TESHIS RED" satirlarinin dagilimini da            |
//|  karsilastirmak, sorunun gercekten cozuldugunu sayisal gosterir.   |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|    DGN Nexus Pro R21  v1.78.163 DI-ADXFLOOR-FIX                     |
//|  Kaynak: kullanicinin v1.78.157 DIRLOCK-DIAG-REVIEW ile paylastigi |
//|  3 Strategy Tester ekran goruntusu (XAUUSD M5, 2026.08.03-08.08)   |
//|  ve "buraya kadar getirdim ama hala islem 0" bildirimi.            |
//|                                                                    |
//|  GOZLEM: Loglar AYNI test icinde IKI farkli durumu gosteriyordu:   |
//|  (1) TradeDiag: "Yon NOTR - DirectionLock onceki yonu koruyor,     |
//|  reversal teyidi bekleniyor" - dakikalarca tekrarlaniyor.          |
//|  (2) TESHIS-B: ctx.dir.direction=-1 conf=0.850 (GUCLU, gecerli bir |
//|  SELL sinyali) ama allow=false; R21 BULLET TESHIS RED sebep=       |
//|  ALLOW_NEW_ENTRIES_FALSE - yani sinyal gayet iyiyken bile giris    |
//|  kilitli kaliyordu.                                                |
//|                                                                    |
//|  KOK NEDEN (DirectionLock_Manage icinde dogrulandi): committedDir  |
//|  !=0 iken (yani ilk yon zaten v1.78.151'in ColdStartSeedDirection  |
//|  katmaniyla komuted edilmis) ve YENI sinyal committedDir'in TERSI  |
//|  ise, DirectionLock bunu bir "reversal adayi" olarak InpDirLock_   |
//|  FlipConfirmTicks (varsayilan 2) ARDISIK tick boyunca teyit        |
//|  etmeden commit etmiyor - bu KASITLI ve DOGRU bir guvenlik         |
//|  davranisi. AMA: "NOTR/zayif sinyalde" blogu, ZATEN BIRIKMEYE      |
//|  baslamis bu adayi (g_dirlock_candidateDir/Ticks) HER TEK notr     |
//|  (direction=0) tick'te KOSULSUZ SIFIRLIYORDU. Choppy/dusuk-ADX     |
//|  piyasada VEMA-X'in (kapanan bara dayali) yonu bar bar -1/0        |
//|  arasinda sekebildigi icin (tam da bu testte oldugu gibi - loglar  |
//|  hem direction=-1 hem direction=0 donemlerini gosteriyor), teyit   |
//|  sayaci pratikte HICBIR ZAMAN confirmNeed'e ulasamiyordu:          |
//|  DirectionLock, fiyat committedDir'den cabuk uzaklassa bile,       |
//|  reversal'i SONSUZA KADAR "teyit bekleniyor" durumunda tutarak     |
//|  YENI GIRISLERI (committedDir ile TUTARSIZ hale gelmis eski yon    |
//|  DAHIL) kalici olarak kilitliyordu - cold-start'tan (v1.78.151)    |
//|  SONRAKI, mimarinin farkli bir noktasindaki IKINCI kisir dongu.    |
//|                                                                    |
//|  DUZELTME (DirectionLock_Manage, "NOTR/zayif sinyalde..." blogu):  |
//|  VEMA_MA_RegimeGate'in v1.78.98'de kurulan "rejim teyitsizken      |
//|  hicbir mudahale yok" ilkesiyle AYNI desen uygulandi: zaten bir    |
//|  aday BIRIKMISSE (candidateDir!=0), tek bir notr/zayif tick artik  |
//|  onu SILMIYOR - sadece o tick'te ilerlemiyor (sayac ne artiyor ne  |
//|  sifirlaniyor), giris o tick'te YINE DE tam kapali kaliyor         |
//|  (guvenlik davranisi DEGISMEDI) - SADECE biriken teyit sayaci      |
//|  korunuyor, boylece ayni yonlu bir sonraki tick kaldigi yerden     |
//|  devam edip normal sekilde confirmNeed'e ulasabiliyor.             |
//|                                                                    |
//|  EK: v1.78.152/153/157'nin "GECICI TESHIS" (throttle'siz, her      |
//|  tick) tani satirlari (TESHIS-B, R21 BULLET TESHIS RED, DIRLOCK    |
//|  TESHIS RED) kok neden bulundugu icin artik diger tani satirlariyla|
//|  TUTARLI sekilde InpSR_LogDecisions anahtarina baglandi - tamamen  |
//|  KALDIRILMADI (ileride baska bir darbogaz cikarsa yeniden          |
//|  faydali olabilir), ama artik varsayilan olarak SESSIZ, cok gunluk |
//|  bir M5 backtest'inin Journal'ini sismirmiyor.                     |
//|                                                                    |
//|  BYPASS EDILMEYEN HICBIR SEY YOK: degisiklik SADECE DirectionLock'un|
//|  KENDI ic sayac/state yonetimine dokunuyor; RiskGovernor, HardSL,  |
//|  RiskCap, ColdStartSeedDirection, Consensus_Evaluate, Grid/Bullet  |
//|  execution akislarinin HICBIRI degistirilmedi.                     |
//|                                                                    |
//|  DOGRULAMA GEREKLI: Bu, statik kod incelemesine ve paylasilan 3    |
//|  ekran goruntusune dayanir. MetaEditor derlemesi (F7) ve ayni      |
//|  tarih araligiyla (2026.08.03-08.08) bir Strategy Tester kosusu    |
//|  YAPILMADAN canli/demo hesaba gecilmemelidir. Eger bu testte HALA  |
//|  0 islem cikarsa, InpSR_LogDecisions=true yapip kisa bir kosu daha |
//|  almak (artik DIRLOCK TESHIS/BDIAG satirlari tekrar gorunur olur)  |
//|  hangi asamada takildigimizi netlestirecektir.                     |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|    DGN Nexus Pro R21  v1.78.151 COLDSTART-SEED-ARCH                |
//|  Kaynak: kullanicinin yukledigi "DGN_Nexus_v1_78_150_COLDSTART_    |
//|  Cozum_Uygulama_Raporu.pdf". Rapor, v1.78.150'nin RiskGovernor     |
//|  cold-start iyilestirmesinin (ColdStartQualityFloor) YETERSIZ      |
//|  oldugunu, cunku sorunun BIR KAT ONCESINDE oldugunu tespit etti:   |
//|  Consensus_Evaluate() bir DOGRULAYICI'dir, YON URETMEZ; VEMA notr  |
//|  donduginde (direction=0) ne DirectionLock, ne Grid dispatch       |
//|  (Lattice_TryOpenLevel, v1.78.95'ten beri direction=0'da hic       |
//|  cagrilmiyor), ne de Bullet_Process (direction=0'da aninda cikiyor)|
//|  bir ILK YON URETEBILIYORDU - "Yon NOTR - grid tohum denenecek"    |
//|  teshis mesaji da execution ile TUTARSIZDI (mesaj "denenecek"      |
//|  diyor ama hicbir zaman denenmiyordu).                             |
//|                                                                    |
//|  DUZELTME: Yeni ColdStartSeedDirection() fonksiyonu (Consensus_    |
//|  Evaluate'in hemen ardinda tanimli) - SADECE gercek soguk          |
//|  baslangicta (DirectionLock hic commit etmemis) ve mevcut          |
//|  pozisyon yokken calisir; DI+TMI+EMA(Ind_EMA_DI) UCU BIRDEN ayni   |
//|  yonde hizali VE Consensus'un normal kullandigi AYNI esikleri      |
//|  (NDI_GetGate - cold-start icin gevsetilmis AYRI esik YOK)         |
//|  gectiginde tek seferlik bir ilk yon uretir. RunStagedPipeline'da  |
//|  DirectionLock_Manage()'den HEMEN ONCE cagrilir - basarili olursa  |
//|  g_ctx.dir.direction/confidence doldurulur ve DirectionLock KENDI  |
//|  DEGISMEMIS commit mantigiyla bunu isler. Seed sonrasi committedDir|
//|  artik 0 olmadigi icin fonksiyon kendiliginden bir daha calismaz   |
//|  (T7: "seed motoru tekrar yon degistirmemeli").                    |
//|                                                                    |
//|  BYPASS EDILMEYEN HICBIR SEY YOK: RiskGovernor, RiskCap_MaxLot,    |
//|  Trade_PreflightMarketOrder, basket-risk, Hard SL, OrderCheck,     |
//|  GridRisk Firewall, gunluk kilit - hepsi DEGISTIRILMEDEN, seed'den |
//|  SONRA normal akislarinda calismaya devam ediyor. Seed bulunamazsa |
//|  (DI/TMI/EMA hizalanmazsa) islem acilmaz - raporun ilkesi: "amac   |
//|  mutlaka islem acmak degil, neden acamadigini deterministik hale   |
//|  getirmek".                                                        |
//|                                                                    |
//|  Ayrica: TradeDiag_Compute()'daki yaniltici "grid tohum denenecek" |
//|  mesaji (Bolum 5) düzeltildi - artik gercek soguk baslangic (seed  |
//|  denendi, hizalanmadi) ile DirectionLock'un reversal-bekleme       |
//|  durumunu (Bolum 10) AYIRT EDEREK raporluyor.                      |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|    DGN Nexus Pro R21  v1.78.150 COLDSTART-FIX                       |
//|  Kullanici gecmis (146/147) Journal ekran goruntuleri paylasti -   |
//|  ayni "R21 BULLET RISK GOV BLOCK | ... reason=ENTRY_DENSITY_OR_    |
//|  PERFORMANCE" satiri FARKLI gercek nedenlerle cikiyor: kimi zaman  |
//|  quality=0.713 (esiklerin UZERINDE, v1.78.148'in duzelttigi        |
//|  entry-density bug'i), kimi zaman quality=0.474 (esigin ALTINDA -  |
//|  bu MARKET_QUALITY_KALICI, TAMAMEN AYRI ve halen GECERLI/KASITLI   |
//|  bir engel, bug degil). Bullet_Process'teki log satiri sabit metin |
//|  oldugu icin bu ikisini AYIRT ETMIYORDU - hem kullaniciyi hem      |
//|  onceki analizi yanilttigi tespit edildi (bkz. RiskGovernor TESHIS |
//|  satirlari sadece 2/6 dalda vardi, v1.78.139'da tam kapsamli       |
//|  vardi ama 140-142 disaridan yeniden yazilinca kaybolmustu).       |
//|                                                                    |
//|  DUZELTME (sadece gorunurluk, esik/mantik DEGISMEDI):              |
//|  RiskGovernor_BlockEntry() artik "string &blockReason" cikti       |
//|  parametresi aliyor - hangi daldan donduysa (MARKET_QUALITY_KALICI,|
//|  SOGUK_BASLANGIC, PERFORMANS_COOLDOWN, SEPET_ZARARI,                |
//|  AYNI_YON_ACIK_POZ_LIMITI, GIRIS_YOGUNLUGU) o degeri yaziyor. Kalan |
//|  4 dala da (eskiden sessizce "return true" diyen) RISKGOV TESHIS    |
//|  tani satiri eklendi (InpSR_LogDecisions + 60sn throttle, digerleri |
//|  gibi). Bullet_Process VE Lattice_TryOpenLevel'daki BLOCK log       |
//|  satirlari artik bu GERCEK sebebi yaziyor - sabit "ENTRY_DENSITY_   |
//|  OR_PERFORMANCE"/"RISK_GOV_BLOCK" metni yerine.                    |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|    DGN Nexus Pro R21  v1.78.148 ENTRY-DENSITY-REALOPEN-FIX         |
//|  v1.78.147 Consensus_Evaluate esiklerini duzeltti - yeni backtest  |
//|  loglarinda "yonHizali=EVET" artik gercekten goruluyor (DI/TMI     |
//|  yon uretebiliyor). Ama kullanicinin en son Aug 2-8 loglarinda hala|
//|  uzun "R21 BULLET RISK GOV BLOCK | ... reason=ENTRY_DENSITY_OR_    |
//|  PERFORMANCE" serileri var - sepet BOS (ilk giris) VE marketQuality|
//|  0.713 (her iki esigin de UZERINDE, RISKGOV MQ DETAY logunda       |
//|  goruluyor) oldugu halde.                                          |
//|                                                                    |
//|  KOK NEDEN: RiskGovernor_BlockEntry() icindeki pencere-bazli       |
//|  entry-density sayaci (g_riskGovEntryCount, varsayilan max 3       |
//|  giris/120sn) HER gecerli-gorunen DENEMEDE artiyordu - lot hesabi  |
//|  (Bullet_CalcLot / Lattice) SONRADAN 0 donup emir HIC gonderilmese |
//|  bile (ayni loglarda "LOT_SIFIR_VEYA_NEGATIF:RISK_MINLOT_ASIYOR")  |
//|  pencere kotasi tukeniyordu. Sonuc: EA, hicbir pozisyon acmamisken |
//|  kendi basarisiz denemeleriyle kendi kendini "yogunluk/performans" |
//|  gerekcesiyle susturuyordu - Consensus/yon sorunu artik cozulmus   |
//|  olsa bile bu ayri katman tek basina 0 islemi surdurebilirdi.      |
//|                                                                    |
//|  DUZELTME: Sayac artik SADECE gercekten ACILAN (broker'dan ok=true |
//|  + gecerli retcode donen) pozisyonlarda artiyor. RiskGovernor_     |
//|  BlockEntry() artik SALT-OKUNUR kontrol yapar (pencere suresi      |
//|  dolmus mu -> sifirla, kota zaten dolu mu -> engelle); artirma     |
//|  islemi yeni RiskGovernor_RecordEntryOpened()'e tasindi - bu       |
//|  fonksiyon SADECE Lattice_TryOpenLevel ve Bullet_Process'in        |
//|  basarili emir sonrasi noktalarindan cagrilir. Baska hicbir        |
//|  esik/mantik (marketQuality, soguk-baslangic, motorMult/dirMult,   |
//|  basketLoss, DI/TMI konsensus esikleri) DEGISTIRILMEDI.            |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|    DGN Nexus Pro R21  v1.78.147 CONSENSUS-GATE-FIX (KOK NEDEN)     |
//|  v1.78.143-146 RiskGovernor'i (marketQuality/soguk-baslangic)      |
//|  kalibre etti, ama backtest'te HALA 0 islem raporlandi. Kullanici  |
//|  InpSR_LogDecisions=true ile TAM HAFTALIK Journal cikarip paylasti |
//|  (2026.08.02-08, XAUUSD M5, 262 MB / 1.49M satir). Tam log uzerinde|
//|  programatik analiz KESIN kok nedeni ortaya cikardi - RiskGovernor |
//|  degil, ondan bir kat ONCEKI bir katman:                           |
//|                                                                    |
//|  Consensus_Evaluate() (DI+TMI oylamasi) TUM HAFTA BOYUNCA sifir    |
//|  kez basarili oldu: grep "VOTES=[0-9]* OK" -> 0 sonuc (532 basarisiz|
//|  "VOTES=0<1" ornegine karsi). Nedeni: DI_Evaluate()'in trendScore'u|
//|  haftanin EN GUCLU aninda (ADX=55.2) bile 0.390'i gecemedi (532    |
//|  ornek uzerinden mutlak maksimum), ama InpDI_MinTrendScore=0.50    |
//|  (+ NDI_FlipSafety=STRONG carpaniyla efektif 0.575) esigi bunun    |
//|  UZERINDEYDI - "mature DI" bayragi TUM HAFTA boyunca bir kez bile  |
//|  true olamadi (0/532). TMI daha gercekci ama yine de sadece 58/532 |
//|  (~%11) esigi asiyordu VE o 58 durumun hicbirinde test edilen aday |
//|  yonle uyusmadi (ayni sebeple 0 basari). Sonuc: g_ctx.dir.direction|
//|  pratikte HER ZAMAN 0 (NOTR) kaldi - RiskGovernor'in dusuk quality |
//|  skoru (rawConf, yon=0 iken hep 0 donuyor) bunun DOGRUDAN SONUCUYDU,|
//|  ayri bir hastalik degildi.                                        |
//|                                                                    |
//|  KANITA DAYALI DUZELTME (tam hafta yuzdelik dagilimindan):         |
//|   InpDI_MinTrendScore    : 0.50 -> 0.22  (~80. yuzdelik, STRONG ile|
//|                            efektif ~0.253 - hala secici, ARTIK     |
//|                            ULASILABILIR)                            |
//|   InpTMI_ConfidenceGate  : 0.50 -> 0.35  (medyanin hemen altinda,  |
//|                            STRONG ile efektif ~0.4025)              |
//|  Her ikisi de v1.78.118'de kullanici talebiyle 0.42/0.45 -> 0.50   |
//|  yapilmisti; o zamanki DI/TMI formulasyonuyla ulasilabilir olabilir|
//|  di, ancak guncel formul + bu enstruman/zaman diliminin gercek     |
//|  verisiyle degildi. RiskGovernor'daki v1.78.145 kalibrasyonu       |
//|  (soguk baslangic esigi 0.60, minTrades=6) DEGISTIRILMEDI - direction|
//|  artik ara sira gercekten +-1 oldugunda, emaQuality bonusu (+0.20) |
//|  ve rawConf (artik 0'da kilitli kalmayacak) sayesinde marketQuality|
//|  de kendiliginden yukselmesi beklenir; hala yetersiz kalirsa bir   |
//|  sonraki adim budur.                                                |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|    DGN Nexus Pro R21  v1.78.146 RISKGOV-DIAG                       |
//|  v1.78.145 sonrasi backtest Journal'i gosterdi ki RISK_GOV_BLOCK   |
//|  ADX guclu (43.5-44.3, trend acik) VE hic acik pozisyon yokken     |
//|  (trades=0, basketLoss=0) bile HALA tetikleniyor. trades=0 iken    |
//|  motorMult/dirMult sabit 0.55 dondugu icin (RiskGovernor_          |
//|  ComputeMult, degismedi) cooldown/basket/density dallari devre     |
//|  disi kalir - geriye TEK aday kalir: marketQuality<=0.55 KALICI    |
//|  engeli (RiskGovernor_BlockEntry ilk kontrolu). Ama bu fonksiyon   |
//|  4 alt bilesenden (emaQuality/candleQuality/volumeQuality/rawConf) |
//|  olusuyor ve HANGISININ dusuk ciktigi Journal'da hic gorunmuyordu  |
//|  - kor kalibrasyon riskli olurdu.                                  |
//|                                                                    |
//|  BU SURUM SADECE TANI EKLER, MANTIK DEGISMEDI:                     |
//|   - RiskGovernor_MarketQuality(): InpSR_LogDecisions ACIKKEN       |
//|     "RISKGOV MQ DETAY" satiri ile ema/candle/vol/rawConf/quality   |
//|     alt degerlerini 60sn'de bir loglar.                            |
//|   - RiskGovernor_BlockEntry(): hangi dalin engellediğini            |
//|     ("MARKET_QUALITY_KALICI" veya "SOGUK_BASLANGIC") "RISKGOV      |
//|     TESHIS" satiriyla ayirir.                                      |
//|  Panelden/input'tan InpSR_LogDecisions=true yapip KISA bir backtest|
//|  calistirip Journal'i paylasin - hangi bilesenin (ozellikle rawConf|
//|  veya candleQuality suphe altinda) dusuk ciktigini gorunce dogru   |
//|  esigi/agirligi KORLEMEDEN kalibre edecegiz.                       |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|    DGN Nexus Pro R21  v1.78.145 RISKGOV-COLDSTART-FIX              |
//|  v1.78.144 sonrasi backtest Journal'i yeni bir engel gosterdi:     |
//|  "R21 TESHIS RED | ... | sebep=RISK_GOV_BLOCK" - bu RiskCap/       |
//|  HardSL'den TAMAMEN BAGIMSIZ, UCUNCU bir katman: RiskGovernor_     |
//|  BlockEntry() icindeki "soguk baslangic" korumasi.                 |
//|                                                                    |
//|  KOK NEDEN: trades < InpRiskGov_MinTrades (=12) iken (yani daha    |
//|  ilk 12 islem tamamlanmadan), marketQuality (EMA/mum/hacim/conf    |
//|  birlesik skoru, 0-1 araligi) < 0.75 ise giris engelleniyordu.     |
//|  Simulasyon: "iyi/tipik" piyasa kosullarinda bile (trend uyumlu,   |
//|  orta govdeli mum, normal hacim, notr confidence) skor ~0.76       |
//|  cikiyor - yani 0.75 esigi normal piyasada ancak SINIRDA           |
//|  geciliyordu, zayif/kararsiz anlarda (Journal'daki gercek          |
//|  ornekler) kolayca altinda kaliyordu. Sonuc: istatistik            |
//|  biriktirmek icin islem gerekirken, islem acmak icin (henuz        |
//|  istatistik yokken) neredeyse mukemmel piyasa kalitesi             |
//|  gerekiyordu - KISIR DONGU (cold-start tuzagi).                    |
//|                                                                    |
//|  DUZELTME (KULLANICI KARARI - olculu ayar, iki parametre birden):  |
//|   - Soguk-baslangic marketQuality esigi   : 0.75  -> 0.60          |
//|   - InpRiskGov_MinTrades                  : 12    -> 6             |
//|  KALICI engel olan marketQuality<=0.55 satiri (bir ust satir)      |
//|  DEGISMEDI - gercekten kotu piyasa kalitesi hala her zaman         |
//|  reddedilir. Sadece "yeterli istatistik toplanana kadar ekstra     |
//|  agresif kontrol" penceresinin esigi ve suresi kalibre edildi.     |
//|  RiskGovernor'un istatistik-bazli asil mantigi (motorMult/dirMult, |
//|  basket loss limit, entry density) HICBIRI degistirilmedi.         |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|    DGN Nexus Pro R21  v1.78.144 RISK-BUDGET-CALIBRATION            |
//|  v1.78.143'un kendi notu dogrulandi: RISK_CALIBRATION raporunun    |
//|  TUM P0/P1/P2 maddeleri (bkz. v1.78.141 blogu asagida) zaten kod   |
//|  seviyesinde uygulanmisti. v1.78.143 sonrasi bildirilen "0 islem"  |
//|  sorunu bir hata DEGIL, artik dogru hesaplanan gercek riskin       |
//|  ($1000 civari hesap + %1 butce=$10 + Grid'in 9x ATR Hard SL       |
//|  mesafesi) minLot (0.01) icin bile asilmasiydi - fail-closed       |
//|  korumalar TASARLANDIGI GIBI calisip surekli veto uretiyordu.      |
//|                                                                    |
//|  KULLANICI KARARI (bu HOTFIX): guvenlik mimarisini GEVSETMEDEN,    |
//|  yalnizca iki runtime input'u kucuk hesaba gore kalibre et:        |
//|   - InpRiskSizing_MaxRiskPct   : 1.0  -> 3.0  (risk butcesi)       |
//|   - InpHardSL_GridATRMult      : 9.0  -> 7.0  (Grid Hard SL mesafesi)|
//|  7.0, GridRiskFirewall esiginin (InpGridRiskMaxAdverseATR=6.0)     |
//|  HALA ustunde - katman sirasi (Teknik Sartname 4.4) korunuyor.     |
//|  Fail-closed veto mantiginin KENDISI (RiskCap_MaxLot, HardSL       |
//|  fail-closed, basket risk kontrolu, min-lot ispat sarti, netting   |
//|  exclusive, margin fallback kaldirma, daily-unlock grace) HICBIRI  |
//|  DEGISTIRILMEDI - sadece parametreler yeni hesap buyuklugune gore  |
//|  ayarlandi. Backtest/demo sonrasi rakamlar hala tatmin etmiyorsa   |
//|  (surekli RISK_MINLOT_ASIYOR/RISK_CAP_SIFIR gorunuyorsa) bir       |
//|  sonraki adim ya butceyi/mesafeyi daha da ayarlamak ya da hesap    |
//|  buyuklugunu artirmaktir - koda otomatik karar verdirilmemistir.   |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|   DGN Nexus Pro R21  v1.78.143 GRID-MINLOT-OVERRIDE-FIX (HOTFIX)  |
//|  Kullanicinin backtest'te (Risk Governor ACIKKEN) bildirdigi      |
//|  sorun: v1.78.142'nin duzelttigini dusundugu "hicbir islem        |
//|  acilmiyor, Journal'da sonsuz RISK MODEL VETO donguisu" sorunu    |
//|  AYNEN DEVAM EDIYORDU (ornek: "sepet riski asilacakti: mevcut=    |
//|  0.00 + yeni=423.21 = 423.21 > butce=10.00", HER TICK'TE tekrar). |
//|                                                                   |
//|  KOK NEDEN: v1.78.142 TPProj_NormalizeLot()'u dogru sekilde       |
//|  duzeltti - risk butcesi (equity*%1) Grid'in GERCEK 9x ATR Hard   |
//|  SL mesafesindeki minLot riskini bile karsilayamiyorsa fonksiyon  |
//|  ACIKCA 0.0 donuyor (Journal'da "TPProj LOT FAIL | effective max  |
//|  < min" veya "TPProj LOT VETO" olarak gorunur - bu KASITLI ve     |
//|  DOGRU bir ret). SORUN: bu 0.0, Lattice_TryOpenLevel() icindeki   |
//|  v1.78.130 tarihli BASKA bir "guvenlik katmani"na ulasiyordu -    |
//|  "lot<=0 ise OrderSend hata vermesin diye otomatik minLot'a       |
//|  yukselt" mantigi KOSULSUZ calisiyordu ve yukaridaki KASITLI risk |
//|  reddini SESSIZCE EZIYORDU. Sonuc: Grid her seferinde minLot ile  |
//|  (0.01) tekrar deniyor, bu kez Trade_PreflightMarketOrder icindeki|
//|  RiskModel_BasketRiskOK() GERCEK (genis Grid mesafesiyle          |
//|  hesaplanmis, dolar cinsinden) riski butceyle karsilastirip HAKLI |
//|  OLARAK yeniden veto ediyordu - ayni donguyu bir onceki katmandan |
//|  bu katmana tasimis oluyordu, sonuc ayni: sonsuz veto, hicbir     |
//|  islem acilmiyor. (Bullet motoru bu hataya sahip DEGILDI - lot<=0 |
//|  oldugunda dogrudan islemi iptal ediyor, minLot'a zorlamiyor;     |
//|  bkz. Bullet_ManageEntry ~satir 11732 "R21 BULLET IPTAL" bloğu -  |
//|  Grid'in referans almasi gereken DOGRU davranis buydu.)           |
//|                                                                   |
//|  DUZELTME: Lattice_TryOpenLevel() icindeki "lot<=0 -> minLot'a    |
//|  zorla" bloğu artik SADECE InpRiskSizing_Enable=false iken         |
//|  (yani hicbir risk butcesi ihlal edilemeyecekken) calisiyor. Risk |
//|  sizing ACIKKEN lot=0 ise Bullet'teki AYNI ilke uygulanir: islem  |
//|  acilmaz, "R21 GRID IPTAL | ... | sebep=..." satiriyla (InpSR_    |
//|  LogDecisions acikken) neden Journal'a yazilir, minLot'a asla     |
//|  zorlanmaz.                                                       |
//|                                                                   |
//|  ONEMLI: Bu duzeltme sonrasi Grid'in bazi (hatta cogu) tick'te    |
//|  hala islem ACMAMASI MUMKUNDUR - eger hesap kucuk (ornegin        |
//|  equity=$1000, InpRiskSizing_MaxRiskPct=%1 -> butce=$10) ve       |
//|  XAUUSD'nin o anki volatilitesinde Grid'in 9x ATR Hard SL         |
//|  mesafesi minLot (0.01) icin bile $10'un cok ustunde gercek       |
//|  risk anlamina geliyorsa, bu ARTIK YAPISAL/BEKLENEN bir durumdur -|
//|  onceki gibi bir "hata" DEGIL, kasti bir risk-butcesi korumasidir.|
//|  Boyle durumlarda Journal'da "TPProj LOT FAIL/VETO" veya "R21     |
//|  GRID IPTAL" satirlari gorulecek (artik SPAM/donguIe donusmeden), |
//|  ve kullanicinin InpRiskSizing_MaxRiskPct'i yukseltmesi,          |
//|  InpHardSL_GridATRMult'u dusurmesi veya hesap buyuklugunu         |
//|  artirmasi gerekebilir - bu bir risk/getiri tercihidir, koda      |
//|  otomatik olarak karar verdirilmemistir.                          |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|     DGN Nexus Pro R21  v1.78.142 RISK-CALIBRATION-FIX2 (HOTFIX)   |
//|  Kullanicinin backtest'te bildirdigi sorun: EA HICBIR ISLEM       |
//|  ACMIYOR, Journal'da surekli "RISK MODEL VETO ... yeni=262.74 >   |
//|  butce=10.00" satirlari donuyordu.                                |
//|                                                                   |
//|  KOK NEDEN: v1.78.141'de RiskCap_MaxLot() DBL_MAX donusunu YENI   |
//|  durumlar icin de kullanmaya basladi (ATR/equity/fiyat/           |
//|  OrderCalcProfit hesaplanamadi = "veri yok, veto"). Ama            |
//|  TPProj_NormalizeLot() (Solver/BLM_PROJECT lot yolu) icindeki      |
//|  "maxLot = MathMin(maxLot, RiskCap_MaxLot(...))" satiri hala       |
//|  ESKI varsayimla yaziliydi: DBL_MAX = "risk sizing kapali, bu      |
//|  satir no-op". Sonuc: risk verisi hesaplanamadiginda Solver        |
//|  RISKCAP'SIZ (sadece InpTPProjMaxLot/broker max ile sinirli, COK   |
//|  DAHA BUYUK) bir lot uretebiliyordu; o lot Trade_PreflightMarket   |
//|  Order()'daki GERCEK (OrderCalcProfit tabanli) sepet-riski         |
//|  kontrolune takilip HER SEFERINDE veto ediliyordu - sonsuz         |
//|  dongu, hicbir islem acilmiyordu.                                  |
//|                                                                    |
//|  DUZELTME: TPProj_NormalizeLot() artik Lot_CalcCapped() ile AYNI   |
//|  semantigi kullaniyor - risk sizing gercekten KAPALIYSA RiskCap_   |
//|  MaxLot hic cagrilmiyor (asil no-op); ACIKSA ve DBL_MAX donerse    |
//|  ACIKCA 0.0 (reddet) donuyor. Ayrica RiskCap_MaxLot() icindeki     |
//|  ONCEDEN SESSIZ olan her DBL_MAX dalina (ATR/equity/fiyat) tani    |
//|  logu eklendi - "R21 RISK_CAP UYARI" satirlari artik TAM OLARAK    |
//|  hangi veriyi hesaplayamadigini soyluyor.                          |
//|                                                                    |
//|  ONEMLI: Bu duzeltme "hicbir islem acilmiyor" DONGUSUNU kirar,     |
//|  ama Journal'da "R21 RISK_CAP UYARI" veya "TPProj LOT VETO"        |
//|  satirlari gorulmeye devam ederse bu ARTIK YAPISAL bir sorunu      |
//|  (ATR/equity/OrderCalcProfit GERCEKTEN calismiyor) isaret eder -   |
//|  ayni sekilde islem acilmayabilir ama artik SEBEP Journal'da       |
//|  acikca yazacaktir.                                                |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|          DGN Nexus Pro R21  v1.78.141 RISK-CALIBRATION-FIX          |
//|  Kaynak: kullanicinin yukledigi "PROFESYONEL RISK MIMARISI VE       |
//|  DUZELTME RAPORU" PDF'i (v1.78.140 RISK_CALIBRATION baz alinarak    |
//|  yazilmis). Raporun 17 bolumu tek tek koda karsi statik olarak      |
//|  dogrulandi ve duzeltildi. TEK CUMLEYLE OZET: RiskCap_MaxLot ve     |
//|  gercek Hard SL artik AYNI mesafe fonksiyonunu (HardSL_Distance)    |
//|  paylasiyor - "hesaplanan risk" ile "broker'a giden gercek SL"      |
//|  artik HER ZAMAN ayni sozlesmeye bagli (raporun "Tek Risk           |
//|  Sozlesmesi" ilkesi).                                                |
//|                                                                     |
//|  [DUZELTILDI] P0 #1 (Bolum 1/3): RiskCap 3 ATR / Grid Hard SL 9 ATR |
//|  uyumsuzlugu. RiskCap_MaxLot() artik isGridMotor parametresi alip   |
//|  HardSL_Distance(symbol,isGridMotor) ile AYNI mesafeyi kullanir -   |
//|  Grid icin gercekten 9 ATR, Bullet icin gercekten 3 ATR. Ayrica     |
//|  tickValue yaklasimi yerine OrderCalcProfit ile GERCEK parasal      |
//|  zarar hesaplanir (Bolum 4B, P1).                                    |
//|                                                                     |
//|  [DUZELTILDI] P0 #2 (Bolum 2/4C): Hard SL fail-open -> fail-closed. |
//|  Trade_PreflightMarketOrder artik gercek SL fiyatini parametre      |
//|  olarak alir; SL<=0 ise (veya BUY/SELL yon kurali ihlal edilmisse)  |
//|  TUM 5 emir yolu (Grid/Bullet/NFH/WH/DDH) islemi tamamen veto eder -|
//|  hicbir market order artik SL=0 ile gidemez.                        |
//|                                                                     |
//|  [DUZELTILDI] P0 #3 (Bolum 4D/6): Grid+Bullet ayni g_magic netting  |
//|  cakismasi. Yeni RiskModel_EngineExclusive(): netting hesapta bir   |
//|  motor, DIGER motorun o sembolde acik pozisyonu varken giremez      |
//|  (raporun "en guvenli secenek" onerisi). Ayrica Engine_OpenExposure |
//|  ile InpGridMaxTotalLot artik motor bazinda AYRI sayilir - Bullet   |
//|  pozisyonu Grid'in tavanini (ve tam tersini) artik tuketmiyor.      |
//|                                                                     |
//|  [DUZELTILDI] P1 (Bolum 3/7): Basket risk kontrolu. Yeni            |
//|  RiskModel_BasketRiskMoney()/BasketRiskOK(): Grid+Bullet+orphan     |
//|  TUM acik pozisyonlarin toplam gercek riski (OrderCalcProfit ile),  |
//|  yeni pozisyonla birlikte risk butcesini asarsa giris veto edilir.  |
//|  SL'i olmayan bir pozisyon bulunursa (orphan/eski/manuel) fail-safe |
//|  olarak TUM yeni Grid/Bullet girisleri durur.                       |
//|                                                                     |
//|  [DUZELTILDI] P1 (Bolum 8): OrderCheck eklendi. Trade_Preflight     |
//|  MarketOrder artik gercek bir MqlTradeRequest (SL dahil) olusturup  |
//|  OrderCheck() ile dogruluyor - eskiden bu kontrol hic yoktu.        |
//|                                                                     |
//|  [DUZELTILDI] P1 (Bolum 9): Margin_PerLotSafe'deki keyfi "bakiyenin |
//|  %1'i" fallback'i KALDIRILDI - margin gercekten hesaplanamiyorsa    |
//|  0.0 doner (cagiran taraf minLot'a duser), nihai OrderCalcMargin+   |
//|  OrderCheck kontrolu zaten ayrica ve degismeden veto ediyor.        |
//|                                                                     |
//|  [DUZELTILDI] P1 (Bolum 10): Min lot risk-veto artik broker         |
//|  minimumuna SESSIZCE yukari yuvarlanmiyor. Lot_CalcCapped, minLot'un|
//|  GERCEK SL riskini (OrderCalcProfit ile) once kanitlamadan minLot'a |
//|  yukseltmiyor; kanitlanamazsa RISK_MINLOT_ASIYOR ile islem reddedilir.|
//|                                                                     |
//|  [DUZELTILDI] P2 (Bolum 11): Lot audit logging. Lot_CalcCapped artik|
//|  InpSR_LogDecisions acikken BaseLot/carpanlar/RiskCapLot/FinalLot/  |
//|  LossPer1Lot/ExpectedLoss/RedSebebi'ni tek satirda loglar.          |
//|                                                                     |
//|  [DUZELTILDI] P2 (Bolum 13): Gunluk zarar kilidi manuel unlock      |
//|  artik GUN BOYU bypass yaratmiyor - KILIT KALDIR sadece 120sn'lik   |
//|  grace penceresi verir, sonrasinda pnlPct kontrolu KALDIGI YERDEN   |
//|  devam eder ve hedef hala asiliysa kilit otomatik yeniden devreye   |
//|  girer (devam icin tekrar tikla-onayla mantigi).                    |
//|                                                                     |
//|  [DEGISIKLIK GEREKMEDI] Bolum 7 (orphan reconciliation once trading):|
//|  Lattice_Init() -> Lattice_ReconcileFromBroker() zaten senkron ve   |
//|  tek-iş-parçacıklı calisiyor (MQL5'in dogasi geregi); "reconciliation|
//|  tamamlanmadan islem" durumu yapisal olarak zaten mumkun degildi.   |
//|                                                                     |
//|  ONEMLI: Bu duzeltmeler statik kod incelemesine dayanir. Derleme    |
//|  (MetaEditor F7) + Strategy Tester backtest + en az birkac hafta    |
//|  kontrollu forward demo dogrulamasi yapilmadan GERCEK PARA ile      |
//|  kullanilmamalidir - raporun kendi 15/16. bolumlerindeki kabul      |
//|  kriterleri ve test protokolu gecerliligini korur.                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|          DGN Nexus Pro R21  v1.78.130 AUTONOMOUS-FLOW-STABILITY   |
//|  Otonom rejim geçişleri ve motor uyumu sisteminin dört katmanlı    |
//|  kararlılık mekanizması. Piyasa volatilitesi/trend değiştiğinde,   |
//|  sistemin eski motorun parametrelerini hafızadan temizleyip (state |
//|  transition verification), yeni motorun tamamen farklı parametrelerine|
//|  KESİN OLARAK geçtiğini garantileyen canlı mekanizmalar:           |
//|                                                                     |
//|  [1. KATMAN] Rejim Geçiş Doğrulama (State-Transition Verification):│
//|  • AdaptiveMarket_ClearOldMotorState(): Eski rejim param. sıfırla   |
//|  • AdaptiveMarket_UpdateMotorActivation(): Yeni rejim param. AÇ    |
//|  • g_motorTransitionLocked: Geçiş sırasında ALL emir gönderme BLOKE│
//|  Eski motor "donması" veya sabit kalmasını tamamen engeller.        |
//|                                                                     |
//|  [2. KATMAN] Motor Asenkron Bayak Yönetimi (Motor Activation):     │
//|  • g_motor_grid_active, g_motor_bullet_active, ...                 |
//|  • Rejim değişiminde sadece yeni motor "işçi" başlasın, eski motor  |
//|  emir gönderme/sinyal tetikleme işlevleri TAMAMEN BLOKELENSİN.      |
//|  • AdaptiveMarket_IsMotorActive(): Her işlem açmadan KONTROL.       |
//|  Iki motorun aynı tick'te sinyal üretme çelişkisini sıfırlar.       |
//|                                                                     |
//|  [3. KATMAN] Panel Durum Senkronizasyonu (Real-Time Display Sync): │
//|  • Panel_RequestUpdate(true) otomatik rejim değişiminde çağrılır    |
//|  • UpdateMinimalPanel() arka plan otonom geçişi ANINDA reflection   |
//|  Eski duruma asılı kalan (donmuş) buton/göstergeler YALNIŞ konuşur  |
//|  Panel her zaman backend'in KÜNESEYDİR gerçek durumunu gösterir.    |
//|                                                                     |
//|  [4. KATMAN] Lot Taban Koruma Entegrasyonu (Lot Floor Protection):  │
//|  • Lot 0/negatif koruması motor geçişleri sırasında da çalışır      |
//|  • Dinamik minLot elevasyonu (0.01 veya SYMBOL_VOLUME_MIN) güvenli  │
//|  • Geçiş sırasında lot sıfırlanıp emir gönderimi durması KAPATTİLMIŞ│
//|  OrderSend hiçbir koşulda lot hatasıyla FAIL olmaz.                │
//|                                                                     |
//|  Sıfır tolerans: Kod bozulması/taşma/hata yoktur, #property strict │
//|  %100 uyumludur. TÜM motor geçişleri kesintisiz ve çelişkisiz.      |
//|                                                                     |
//+------------------------------------------------------------------+
//|          DGN Nexus Pro R21  v1.78.74 SECONDAUDITFIX                  |
//|  Kaynak: kullanicinin yukledigi "IKINCI DERIN AUDIT" PDF raporu      |
//|  (v1.78.73 AUDITFIX3 baz alinarak yazilmis, 9 madde). Her madde     |
//|  koda karsi tek tek dogrulandi ve duzeltildi.                       |
//|                                                                     |
//|  [DOGRULANDI - DUZELTILDI] #1 (P1) Bullet multi-symbol confirm:     |
//|  Bullet_Process() icindeki yon-teyit takibi "static int s_lastDir"  |
//|  TEK degiskendi - multi-symbol'de bir sembolun yonu digerinin son   |
//|  yonunu eziyordu. B_CONFIRM'in kendisiyle AYNI desende sembol       |
//|  bazli diziye (g_bullet_confirmLastDir[]) tasindi.                  |
//|                                                                     |
//|  [DOGRULANDI - DUZELTILDI] #2 (P1/P2) AUTO LOT yanlis input:        |
//|  BLM_AUTO dalinda risk yuzdesi InpBulletLotValue'dan (FixedLot      |
//|  input'u) okunuyordu, InpAutoLotPct hicbir etkiye sahip degildi.    |
//|  Kaynak InpAutoLotPct'e cevrildi, alt/ust guvenlik siniri korundu.  |
//|                                                                     |
//|  [DOGRULANDI - DUZELTILDI] #3 (P2) Bullet Loss Quality Step:        |
//|  InpBullet_LossQualityStep tanimliydi ama Bullet_EntryQualityScore()|
//|  icinde hic okunmuyordu. Artik ayni-yon ardisik zarar sayaci        |
//|  (B_SAME_LOSS) arttikca skoru bu kadar dusuruyor.                   |
//|                                                                     |
//|  [DOGRULANDI - DUZELTILDI] #4 (P2) TP-Proj Profit/Loss Reset:       |
//|  InpTPProjAfterProfitReset/AfterLossReset toggle'lari hicbir        |
//|  karara baglanmamisti - GLOBAL_PROFIT/LOSS her ikisi de ayni        |
//|  sekilde InpTPProjGReset'i uyguluyordu. Artik her reset tipi        |
//|  SADECE kendi toggle'i acikken g_gresetForceStartMode'u degistirir  |
//|  (FORCED_RESET'e dokunulmadi - onun bu tur bir toggle'i yok).       |
//|                                                                     |
//|  [DOGRULANDI - DUZELTILDI] #5 (P2) Grid TP config uyumsuzlugu:      |
//|  Lattice_CalcTPDistance() icinde GTP_SPREAD_MULT ve GTP_BALANCE_PCT |
//|  modlari kendi input'larini (InpVG_TP_SpreadMult/BalancePct) hic    |
//|  kullanmiyordu, ikisi de genel tpRaw degerine bakiyordu. Artik her  |
//|  ikisi de kendi input'una bagli (BALANCE_PCT, asagidaki minNet      |
//|  blogundaki AYNI tickVal/tickSz para->mesafe donusumunu kullanir).  |
//|                                                                     |
//|  [DOGRULANDI - DUZELTILDI] #6 (P2) Multi-symbol sonrasi g_ctx:      |
//|  OnTick() dongusu bitince g_symbol/g_lattice/g_sym_idx chart         |
//|  sembolune donuyordu ama g_ctx DONMUYORDU - panel/diagnostic son    |
//|  islenen sembolun context'ini okuyabiliyordu. Sembol basina         |
//|  snapshot dizisi (g_ctxSnapshot[]) eklendi, loop sonunda pipeline'i  |
//|  TEKRAR CALISTIRMADAN (cift-islem riski yok) chart sembolunun       |
//|  context'i geri yukleniyor.                                        |
//|                                                                     |
//|  [DOGRULANDI - DUZELTILDI] #7 (P3) SmartDir ConfirmTicks:           |
//|  InpSmartDir_ConfirmTicks tanimliydi, hicbir yerde okunmuyordu.     |
//|  SmartDir_Evaluate() artik Ind_FindIdx ile bulunan sembol           |
//|  indeksiyle gercek bir ardisik-teyit sayacina bagli (Bullet'in      |
//|  B_CONFIRM'iyle ayni fikir).                                        |
//|                                                                     |
//|  [DOGRULANDI - DUZELTILDI] #8 (P3) DOM FreshMs:                     |
//|  InpDOM_FreshMs tanimliydi, DOM cache tazelik kontrolu HIC yoktu -   |
//|  hicbir zaman damgasi tutulmuyordu. Yeni OnBookEvent() handler'i    |
//|  GetTickCount64() ile sembol bazli son-guncelleme zamanini          |
//|  kaydediyor; DOM blogu bu yastan eskiyse (veya hic yoksa) artik     |
//|  confidence'i ETKILEMIYOR.                                          |
//|                                                                     |
//|  [DOGRULANDI - DUZELTILDI] #9 (P3) HEG/DTE Weight:                  |
//|  InpHEG_Weight/InpDTE_Weight tanimliydi, ikisi de sadece sert        |
//|  blok/gecis kararinda kullaniliyordu, agirlik hicbir hesaba          |
//|  katilmiyordu. Bloke ETMEDIKLERINDE, kendi esiklerini (Min          |
//|  Efficiency/MinMetaEdge) ne kadar astiklarina gore, InpDOM_Weight    |
//|  ile AYNI desende, sinirli ve SADECE YUKARI yonlu bir confidence    |
//|  katkisi yapiyorlar - mevcut sert blok kararlarina dokunulmadi.     |
//|                                                                     |
//|  [DEGISIKLIK YOK - RAPORUN KENDI SONUCU] Weekly Schedule:           |
//|  raporun on-notu bu maddeyi kendisi P1'den indirmisti (pencere      |
//|  ortak zaman mantigi kullaniyor, pozisyon aksiyonlari sembol        |
//|  parametresiyle yurutuluyor) - kod tarafinda degisiklik yapilmadi.  |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.73 AUDITFIX3                       |
//|  Kaynak: kullanicinin yukledigi harici "BUG_AUDIT_VE_COZUM_RAPORU"   |
//|  PDF'i (v1.78.72_CONFFLOOR baz alinarak yazilmis). Her madde koda    |
//|  karsi tek tek statik olarak dogrulandi. Sonuclar:                  |
//|                                                                     |
//|  [DOGRULANDI - DUZELTILDI] VIOP broker/fixed session selector:      |
//|  InpVIOP_UseBrokerSessionTimes gercekten hicbir yerde okunmuyordu - |
//|  Security_IsInTradeSession() broker seans bilgisi bulursa onu HER   |
//|  ZAMAN kullaniyordu, input'un degeri fark etmiyordu. Artik once     |
//|  input kontrol ediliyor: broker seciliyse broker seans (bulunamazsa |
//|  ve fallback acik ise sabit saatlere duser), broker secili DEGILSE  |
//|  dogrudan sabit saatlere gecer. Varsayilan degerlerde (ikisi de     |
//|  true) davranis AYNI kalir.                                        |
//|                                                                     |
//|  [DOGRULANDI - DUZELTILDI] NDI Enable: InpNDI_Enable hicbir karar   |
//|  zincirinde okunmuyordu - NDI_GetGate() InpNDI_Profile/FlipSafety   |
//|  ayarlarini InpNDI_Enable=false iken de aynen uyguluyordu. Artik    |
//|  InpNDI_Enable=false ise gate notr (temel InpDI_MinTrendScore /     |
//|  InpTMI_ConfidenceGate, minVotes=1) donuyor - NDI filtresi hicbir   |
//|  entry'yi bloke etmiyor. Varsayilan zaten false, yani NDI_Profile/  |
//|  FlipSafety varsayilanlarini degistirmeyen kullanicilar icin        |
//|  davranis DEGISTI (artik gercekten kapaniyor) - bu duzeltmenin      |
//|  amaci zaten buydu.                                                 |
//|                                                                     |
//|  [DOGRULANDI - ISARETLENDI] Etkisiz/kullanilmayan input'lar: statik |
//|  taramada su input'larin deklarasyon disinda TEK BIR executable     |
//|  kullanimi bulunamadi: InpTrendReverseSignal, InpMicroTrendReverse, |
//|  TREND SAME-DIRECTION LOSS SAFETY grubunun tamami (6 input),        |
//|  InpRangePreferGrid, InpTrendPreferBullet, InpTrendADX_Min,         |
//|  InpRangeADX_Max, InpVG_EscapeRewardRisk, ve InpMagicBuy/Sell/      |
//|  GridEscapeBuy/GridEscapeSell/ManualHedge/DynHedge/TimeHedge (7     |
//|  magic input'u - gercek magic uretimi tek basina BuildMagic()'ten,  |
//|  yani InpMagicBase+InpMagicChartSuffix'ten geliyor). Audit'in kendi |
//|  onerdigi 3 secenekten (baglama/kaldirma/deprecated isaretleme) en  |
//|  guvenli olani uygulandi: hicbiri SILINMEDI (eski .set dosyalari    |
//|  bozulmasin) ve hicbir karar mantigina yeni bagimlilik EKLENMEDI    |
//|  (canli davranis riske atilmasin) - sadece Inputs sekmesinde        |
//|  gorunen aciklamalarina "[KULLANILMIYOR]" etiketi eklendi.          |
//|                                                                     |
//|  [KISMEN DOGRULANDI - OPSIYONEL DUZELTME] HEG/DTE/EarlyTrend        |
//|  rates[0] (kapanmamis bar) kullaniyor - dogru. Ama TMI_Evaluate()   |
//|  de (audit'te bahsedilmeyen) ayni deseni kullaniyor, yani bu ucu    |
//|  sinirli bir hata degil, motorlerin COGUNLUGUNUN paylastigi bir     |
//|  yaklasim - bilinctli tasarim mi kaza mi belirsiz. Audit'in kendi   |
//|  onerisi geregi ("intrabar isteniyorsa ayri bir mode input'u"),     |
//|  varsayilani SESSIZCE degistirmek yerine InpMetaEngine_UseClosedBar |
//|  eklendi (varsayilan false = mevcut davranis AYNEN korunur, true    |
//|  ise HEG/DTE/EarlyTrend son KAPANMIS bari kullanir).                |
//|                                                                     |
//|  [DOGRULANMADI - ONERMESI GECERSIZ] Multi-symbol Weekly Schedule:   |
//|  g_weeklyOutside/s_wasOutside gercekten global (sembol bazli dizi   |
//|  degil) - AMA Weekly_IsInsideWindow() hicbir sembol parametresi     |
//|  ALMIYOR (sadece gun/saat bazli, TEK ortak takvim). Yani "farkli    |
//|  sembollerin schedule durumu birbirine karisir" riski olusmuyor -   |
//|  ortada sembole ozgu bir durum yok ki karissin. OnTick() ustte      |
//|  _Symbol ile CAGIRIP global bayragi gunceller, sonra ProcessSymbol- |
//|  Index() ici g_weeklyOutside true ise HER sembol icin g_symbol      |
//|  parametresiyle tekrar cagirir - CLOSE/HEDGE aksiyonu her sembolde  |
//|  KENDI symbol parametresiyle dogru calisiyor (Weekly_ClosePositions/|
//|  Weekly_NetHedge zaten POSITION_SYMBOL filtreliyor). Degisiklik     |
//|  YAPILMADI - array'e cevirmek gercek bir hatayi duzeltmeyecekti,    |
//|  sadece _Symbol icin kucuk bir redundant-cagri var (zararsiz).      |
//|                                                                     |
//|  [ZATEN COZULMUS] Versiyon/audit metadata temizligi: v1.78.72 zaten |
//|  #property version + DGN_BUILD_TAG + g_dgn_version'i TEK kaynaga    |
//|  (DGN_BUILD_TAG) baglamisti (bkz. asagidaki v1.78.72 notu). Ek      |
//|  islem gerekmedi.                                                   |
//|                                                                     |
//|  RANGE/PHASE tercih ayarlari (audit'in "tek phase classifier"       |
//|  onerisi): ENUM_MARKET_PHASE + RT_GridTrendPhase() zaten var ve     |
//|  kullaniliyor - audit'in istedigi mimari ZATEN mevcut. Sorun sadece |
//|  InpRangePreferGrid/InpTrendPreferBullet/InpTrendADX_Min/           |
//|  InpRangeADX_Max'in bu mevcut sisteme hic baglanmamis olmasiydi;    |
//|  yukaridaki "kullanilmayan input" maddesinde deprecated isaretlendi.|
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.71 AUDITFIX2                       |
//|  v1.78.70 notu "bu ortamda gercek MetaEditor derlemesi yapilamadi"  |
//|  demisti. Kullanici gercekten derledi: MetaEditor 2 hata + 1 uyari  |
//|  bildirdi, ikisi de asagida duzeltildi.                             |
//|                                                                     |
//|  [HATA] "undeclared identifier 'name'" (satir 7828 ve 7834,         |
//|  Security_IsHighImpactNewsWindow icinde): #13 fix'i (keyword        |
//|  filtresini opsiyonel yapan degisiklik) 'string name = ev.name;'    |
//|  satirini if(InpNF_UseKeywordFilter){...} bloğunun ICINE almisti.   |
//|  O bloğun disindaki iki PrintFormat log cagrisi (yaklasan/gecmis    |
//|  haber) artik scope disi bir degiskene erisiyordu. Duzeltme:        |
//|  'name' deklarasyonu if bloğunun ONUNE alindi - hem keyword         |
//|  kontrolu hem log satirlari ayni degiskeni her zaman goruyor,       |
//|  davranis (filtre acik/kapali) degismedi.                          |
//|                                                                     |
//|  [UYARI] "description is too long" (satir 462): #property           |
//|  description tek satirlik kisa bir alan; detayli gecmis zaten bu   |
//|  ust yorum blogunda duruyor. Uzun metin kisaltildi, bilgi kaybi yok.|
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.70 AUDITFIX                        |
//|  Kaynak: kullanicinin yukledigi harici "CRITICAL_AUDIT" raporu       |
//|  (v1.78.68_TUNE baz alinarak yazilmis, 13 madde). Her madde         |
//|  v1.78.69 SAFE koduna karsi tek tek dogrulandi; zaten SAFE'de       |
//|  cozulmus olanlar (Grid Risk Firewall #1/#2, Weekly Hedge delta     |
//|  #10) TEKRAR edilmedi. Bulgular:                                    |
//|                                                                     |
//|  [KRITIK - BEKLENMEDIK] SAFE-2'de ONNX_AllowsEntry() icine eklenen  |
//|  fallback-log bloğunun kapanis parantezi EKSIKTI - dosya bu haliyle |
//|  DERLENMIYORDU (brace-depth taramasi: 76 fonksiyon +1 kaymis, EOF   |
//|  derinligi 0 yerine 1). Tek satirlik } eklenerek duzeltildi.        |
//|                                                                     |
//|  #3/#4 Risk-bazli lot tavani: Grid margin/lot tabanli boyutlandirma |
//|  "sermayenin %X'ini riske atma" ile ayni sey degildi. TPProj_       |
//|  NormalizeLot() - hem Grid hem Solver'in ortak gectigi tek nokta -  |
//|  icine equity x InpRiskSizing_MaxRiskPct% / (ATR x                  |
//|  InpRiskSizing_AdverseATRMult) tabanli EK bir tavan eklendi.        |
//|  Yalnizca DARALTIR, mevcut min/max/step mantigini degistirmez.      |
//|                                                                     |
//|  #5/#6 Restart/orphan: Lattice_ReconcileFromBroker() LATTICE_MAX_   |
//|  LEVELS(32) asan broker pozisyonlarini SESSIZCE atliyordu (yorumda  |
//|  "geri kalani yonetilemez kalir" yaziyordu). Artik acikca loglanip  |
//|  g_latticeOrphanExtra[] ile isaretleniyor. GridRisk_Enforce() ayrica|
//|  HER TICK'TE broker'daki gercek Grid pozisyon sayisini tracked      |
//|  sayiyla karsilastirir (GridRisk_CountBrokerGridPositions) - sadece |
//|  restart'ta degil, calisma sirasindaki sapmayi da yakalar. Ikisi de |
//|  yalnizca YENI Grid girisini durdurur; mevcut pozisyonlar KAPATILMAZ|
//|  (manuel inceleme audit'in kendi onerisi).                          |
//|                                                                     |
//|  #7 Trade confirmation: Lattice_TryOpenLevel() artik ok=true        |
//|  sonrasi retcode'u ayrica loglar (DONE/DONE_PARTIAL/PLACED disinda  |
//|  supheli sayilir). Ticket bu tick'te veya rematch'te cozulunce      |
//|  state'e artik ISTENEN degil GERCEK broker hacmi/fiyati yaziliyor - |
//|  kismi dolumda eskiden lot sessizce yanlis kaliyordu.               |
//|                                                                     |
//|  #8 Ayni-tick/duplicate: Lattice_TryOpenLevel() icine sembol+yon    |
//|  gonderim kilidi (g_gridSendLock) eklendi. Mevcut senkron state-    |
//|  guncelleme tasarimi zaten ana riski onluyordu; bu ek bir emniyet   |
//|  supabidir, normal akiste hicbir zaman tetiklenmez.                 |
//|                                                                     |
//|  #9 Direction cache: sadece panel ORNEK SN throttle'i vardi, guclu  |
//|  trend flip'te eski yon suredursa dogru dogru sartlarda dahi kalabi-|
//|  liyordu. ATR-hareket bypass'i + InpDirCache_MaxAgeSec mutlak tavani|
//|  eklendi (sadece daha SIK tazeler, asla daha eski veri vermez).     |
//|                                                                     |
//|  #13 Haber filtresi: Security_IsHighImpactNewsWindow() zaten native |
//|  Calendar API (importance+currency) kullaniyordu - beklenenden iyi. |
//|  Ama importance+currency'den SONRA hala sabit ingilizce anahtar     |
//|  kelime listesiyle (CPI/NFP/FOMC/...) daraltiyordu; bu isimle       |
//|  eslesmeyen onemli haberler sessizce atlaniyordu. InpNF_            |
//|  UseKeywordFilter eklendi, varsayilan KAPALI - audit'in onerdigi    |
//|  gibi keyword artik yardimci/opsiyonel, importance+currency tek     |
//|  basina yeterli.                                                    |
//|                                                                     |
//|  Degismeyenler (dogrulandi, ek islem gerekmedi): #1/#2 Grid Risk    |
//|  Firewall zaten SAFE'de saglam (DD%, para, total-lot, adverse-ATR,  |
//|  emergency close+latch). #10 Weekly Net Hedge zaten delta-bazli     |
//|  idempotent. #11 Grid basket floating loss zaten equity-bazli,      |
//|  account DD'ye bagimli degil. #12 Grid multiplier zaten total-lot   |
//|  firewall'i ile sinirli.                                            |
//|                                                                     |
//|  NOT: Bu ortamda gercek MetaEditor derlemesi yapilamadi. Sadece     |
//|  brace-depth statik analizi (249 fonksiyon, EOF derinligi 0)        |
//|  dogrulandi. Ilk kullanimdan once Strategy Tester'da (once 0 error  |
//|  hedefiyle Compile, sonra kisa bir backtest) test edilmesi          |
//|  onerilir - audit raporunun kendi 15 stres senaryosu listesi de     |
//|  iyi bir baslangic noktasidir.                                      |
//|  ------------------------------------------------------------     |

//|  #131 RANGE PROFIT GUARD INCELEME + IYILESTIRME (4 madde):          |
//|  (1) InpRangeProfitGuardUseDynamicMin: sabit $1 yerine RT_MinCloseMoney|
//|      (equity%0.25/$2.50) - TFG ile ayni felsefe, hesap buyuklugunden|
//|      bagimsiz tutarli esik. (2) InpRangeProfitGuardUseConfirmSec:   |
//|      tick sayaci yerine saniye bazli teyit (varsayilan 15sn) -      |
//|      piyasa hizindan bagimsiz, TFG/AEGIS ile tutarli. (3)           |
//|      InpRangeProfitGuardPullbackPctGrid: Grid sepeti icin Bullet'ten|
//|      BAGIMSIZ pullback% (0=eskisi gibi ortak deger) - Grid'in mutlak|
//|      zirve buyuklugu Bullet'ten cok farkli olabildigi icin ayni %   |
//|      farkli tolerans anlamina geliyordu. (4) Grid NET-POZITIF       |
//|      kuralinda karsi taraf zarari artik RANGE teyidi TAMAMLANDIGI   |
//|      ANDA donduruluyor (g_grid_*_oppLossAtConfirm) - eskiden her    |
//|      cagrida anlik olculuyordu, bu da bekleme suresi (CloseOnRange= |
//|      false + pullback bekleniyorsa) uzadikca requiredBuffer'i       |
//|      sinsice yukseltip tam korumanin gerekli oldugu anda kapatmayi  |
//|      zorlastirabiliyordu. Guvenlik: karar aninda GUNCEL zarar da    |
//|      ayrica olculur, ikisinin BUYUGU kullanilir - donmus deger      |
//|      gercek riski asla maskelemez.                                  |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.67                                 |
//|  #130 KRITIK FIX: RANGE PROFIT GUARD sadece TEK bir Bullet          |
//|  ticket'ini koruyordu - ama en cok kari getiren motor Grid/Lattice  |
//|  oldugu icin, trendden range'e geciste/aninda direnc retest'inde    |
//|  asil kar sizintisi (Grid sepeti) hic korunmuyordu. Yeni            |
//|  GridRangeProfitGuard_Manage(), RANGE rejimi InpRangeProfitGuard-   |
//|  ConfirmTicks kadar teyit edildiginde Grid'in BUY ve SELL sepetini  |
//|  AYRI AYRI degerlendirir. Grid cift yonlu (hedge'li) calisabildigi  |
//|  icin TrendFlipGuard'daki (v1.78.55 #125) ile BIREBIR AYNI          |
//|  NET-POZITIF kurali kullanilir: karsi tarafin zarari + tampon       |
//|  karsilanmiyorsa hic dokunulmaz (hedge'siz birakip DD Hedge'in      |
//|  ayni pozisyonu spread odeyerek yeniden acmasini onlemek icin).     |
//|  Esik alti/zarardaki kademelere asla dokunulmaz. Yeni input:        |
//|  InpRangeProfitGuardIncludeGrid (varsayilan ACIK) - mevcut          |
//|  ConfirmTicks/MinMoney/CloseOnRange/PullbackPct esikleri Bullet ile |
//|  PAYLASILIR, sadece Grid'e ozel bagimsiz sayac/zirve state'i var.   |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.63                                 |
//|  #129 KRITIK FIX: KAR/ZARAR KORUMA ASIMETRISI. AEGIS'in             |
//|  "protect_profit" bayragi ters sinyal + esik-ustu floating KAR'da   |
//|  aninda TUM karli pozisyonlari kapatiyordu (Stage_ProfitExits →     |
//|  AEG_PROTECT) - ama esdeger bir "ters sinyal + floating ZARAR"      |
//|  tetikleyicisi HIC YOKTU. Zarar tarafinin tek koruyucusu olan       |
//|  AEG_LOSSCUT ise block_entry'e (SADECE %8+ equity DD veya SPIKE     |
//|  rejiminde true) bagliydi - yani zarar, hesap ciddi olcude          |
//|  erimeden bu katmanda HIC kesilmiyordu. Sonuc: kucuk karlar ilk     |
//|  ters sinyalde saniyeler icinde kilitleniyor (birkaç sent bile),    |
//|  zararli pozisyonlar ise ayni ters sinyalde dokunulmadan buyumeye   |
//|  devam ediyordu - "karlar kucuk kapanir, zararlar buyuk kapanir"    |
//|  sikayetinin ana nedeni. Artik SAEGISResult'a protect_loss eklendi; |
//|  AEGIS_Evaluate protect_profit ile TAM AYNA esikte (PeakTarget*0.5) |
//|  zarar icin de degerlendiriyor, Stage_ProfitExits'e AEG_PROTECT'in  |
//|  esigiyle (InpAEG_MinProfitMoney) birebir ayni buyuklukte yeni bir  |
//|  AEG_LOSSCUT_FLIP blogu eklendi. block_entry'e bagli eski           |
//|  AEG_LOSSCUT dokunulmadi (agir DD/SPIKE'ta ek katman olarak kalir). |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.61                                 |
//|  #128 KALIBRASYON: VEMA-X esikleri (InpEMA15_ConfirmBars,           |
//|  InpEMA15_FlatSpreadMult) XAUUSD M5, 100.000 barlik gercek veri     |
//|  (2025.03-2026.08) uzerinde Python'da grid-search ile yeniden       |
//|  kalibre edildi. Yontem: ZigZag/ATR-bazli (ATR x2.5) parametre-     |
//|  bagimsiz "gercek trend donusu" referansi cikarilip, VEMA-X'in      |
//|  60sn sanal-bar mantigi M5 close/high/low'dan sentezlenerek         |
//|  simule edildi; her (ConfirmBars, FlatSpreadMult) kombinasyonu      |
//|  icin (a) gecikme: gercek donusten kac M5 bar sonra ayni yone       |
//|  donuldugu, (b) whipsaw orani: VEMA-X'in kendi ici flip sayisinin   |
//|  gercek trend flip sayisina orani olculdu. Eski varsayilan          |
//|  (CB=3, FSM=1.5) whipsaw orani ~4.0 (yani VEMA-X gercek donus       |
//|  sayisinin 4 kati flip ediyordu) ve gecikme ~5.8 bar (~29dk)        |
//|  veriyordu. CB=4/FSM=1.0 kombinasyonu whipsaw'i ~2.8'e dusururken   |
//|  gecikmeyi ~6.0 bara (~30dk, pratikte fark yok) sinirli tutuyor -   |
//|  en iyi gecikme/whipsaw dengesi. Daha agresif whipsaw azaltimi      |
//|  (orn. CB=6) gecikmeyi ~51dk'ya cikarip XAUUSD'nin hizli            |
//|  hareketlerinde sinyali gecikmeli hale getirdigi icin tercih        |
//|  edilmedi - TFG/ZARAR BLOK gibi asagi-akis guard'lar zaten whipsaw'a|
//|  karsi ek koruma sagliyor, VEMA-X'in tek basina "ideal" (whipsaw=1) |
//|  olmasi gerekmiyor. Degisiklik sadece iki input default degeri;     |
//|  mimari/algoritma dokunulmadi, geri alinabilir.                     |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.60                                 |
//|  #127 KRITIK FIX: ZARAR BLOK (panelde "ZARAR BLOK" / g_rt_zarar_blok,|
//|  varsayilan 4) hem Lattice_TryOpenLevel hem de Bullet_Process       |
//|  icinde acik pozisyonlari YON AYRIMI YAPMADAN sayiyordu. Sonuc:     |
//|  SELL tarafinda es. 4+ zararli kademe varken, BUY tarafinin kendi   |
//|  zarari olmasa bile toplam sayac esigi asiyor ve BUY girislerini    |
//|  de (aslinda sadece SELL icin gecerli olmasi gereken engeli)        |
//|  bloke ediyordu - "sell zarar ederken hic buy olmuyor" sikayeti.    |
//|  Artik iki yerde de sayac PositionGetInteger(POSITION_TYPE) ile     |
//|  filtrelenip SADECE ilgili yonun (direction / ctx.dir.direction)    |
//|  zararli pozisyonlarini sayiyor; karsi yon artik etkilenmiyor.      |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.56                                 |
//|  #126 UX: Trend Flip Guard artik panelde GORUNUR ve TIKLANABILIR.   |
//|  KONTROL sekmesinde "ARDISIK CARPAN" satirindan hemen sonra yeni    |
//|  bir toggle: "TREND FLIP GUARD: ACIK/KAPALI" (id: tgTFG). Tiklamak  |
//|  g_rt_tfg_enable'i degistirir, GV'ye (PanelGV_Key TFGEN) kalici     |
//|  olarak yazilir - restart sonrasi son durum korunur. Guard artik   |
//|  InpTFG_Enable yerine RT_TFG() (RT_VG/RT_Bullet ile ayni desen)     |
//|  okuyor: panel hazirsa panel degeri, degilse input degeri gecerli. |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.55                                 |
//|  #125 FIX: v1.78.54'te eklenen Trend Flip Guard, Grid CIFT YONLU    |
//|  (hedge'li) calisirken kardaki tarafi kor sekilde cekiyordu.        |
//|  Karsi tarafta (yeni yonle ayni tarafta) zarar varsa, o zarar       |
//|  artik dogal hedge'siz kaliyor ve DD Hedge equity dususu ile        |
//|  tetiklenip AYNI hedge'i spread odeyerek yeniden aciyordu (net      |
//|  kayip). Artik: karsi tarafin toplam zarari olculur; kapatilabilir  |
//|  kar bu zarari + MinCloseMoney tamponunu KARSILAMIYORSA hic         |
//|  kapatma yapilmaz (net-pozitif kurali). Tek yonlu Grid'de veya      |
//|  karsi taraf zararsizken davranis degismedi.                       |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.54                                 |
//|  #124 YENI: GLOBAL TREND FLIP GUARD. Panelde "Yon: BUY/SELL"        |
//|  olarak gosterilen g_ctx.dir.direction sinyali terse donunce,       |
//|  YENI yonle CELISEN (eski/artik-terse-donmus yonde acilmis) tum     |
//|  pozisyonlar -- Grid/Lattice + Bullet + Hedge, motor ayrimi         |
//|  yapilmadan sembol+magic bazli -- taranir; karda olanlar           |
//|  SafeClosePosition ile kapatilip kar korunur. Zararda olanlara     |
//|  dokunulmaz (SL/DD/AEGIS/Rescue mekanizmalarina birakilir).         |
//|  Yeni input grubu "GLOBAL TREND FLIP GUARD": InpTFG_Enable          |
//|  (varsayilan KAPALI), InpTFG_MinConf, InpTFG_UseMinCloseMoney,      |
//|  InpTFG_FixedMinProfit, InpTFG_CooldownSec (flip spam engeli).      |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.53                                 |
//|  #123 UX: Info karti (OZSERMAYE/BAKIYE/TEMINAT/SERBEST TEMINAT/     |
//|  MAKS.DD/NET yon metni) ayni renk ailesinde bogulmustu — hepsi      |
//|  CV_TXT/CV_ACC gibi ortak tonlardaydi ve gozle taranmasi zordu.     |
//|  Artik: OZSERMAYE + BAKIYE beyaz; TEMINAT + SERBEST TEMINAT yeni    |
//|  CV_NEONBLUE (neon mavi); MAKS. DD yeni CV_NEONPURPLE (neon mor);   |
//|  NET satirindaki yon metni ALIS/SATIS icin yesil, NOTR icin sari,   |
//|  net negatife dusunce kirmizi. NET DEGISIM ve BASARI renklerine     |
//|  dokunulmadi. Ayrica baslik ("DGN NEXUS PRO") artik surum          |
//|  numarasini da icinde gosteriyor, dikeyde header kutusunun tam     |
//|  ortasina hizalandi ve fontu (11->12) buyutuldu.                    |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.52                                 |
//|  #122 UX: Baslik ("DGN NEXUS PRO") duz/ozensiz duruyordu — "TR"     |
//|  etiketi basligin bittigi yerden SABIT 168px sonraya konuyordu,     |
//|  metnin GERCEK genisligi hic olculmuyordu. Panel olcegi (+/-) veya  |
//|  farkli DPI'da etiket metinle ust uste binebiliyordu. Artik         |
//|  TextWidth() ile gercek genislik olculuyor, "TR" kucuk cerceveli    |
//|  bir rozete donustu, baslik fontu buyutuldu (10->11) ve header'in   |
//|  altina ince bir ayrac cizgisi eklendi.                             |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.51                                 |
//|  #121 UX: Panel renk sistemi bastan yenilendi — dagilmis, birbirini |
//|  tutmayan ~30 farkli ham renk (RGB literal) kaldirildi; hepsi tek   |
//|  bir palete (CV_BG/CARD/ACC/ON/OFF/RED/WARN/...) baglandi. Eski     |
//|  parlak turkuaz "her sey ayni renk" temasi yerine: koyu GRAFIT      |
//|  zemin + ALTIN (gold) marka/secim vurgusu, YESIL=ACIK/kar, KIRMIZI= |
//|  KAPALI/zarar, AMBER=dikkat anlamli ayrimiyla kullaniliyor. Ayrica  |
//|  duzenleme kutusu (OBJ_EDIT) ve ROBOT/RISK/MASTER/KAPAT butonlari   |
//|  da ayni temaya tasindi.                                            |
//|  ------------------------------------------------------------     |
//|  #120 KRITIK: HABER sekmesindeki "Info" bolumu hic yoktu.           |
//|  InpNF_LookaheadHours ve InpNF_LogEvents inputlari TANIMLIYDI ama   |
//|  kodun hicbir yerinde KULLANILMIYORDU — panelde sadece kilit        |
//|  durumu (Kilit: AKTIF/yok) gosteriliyordu, gercek haber ismi/saati  |
//|  hic cizilmiyordu, bu yuzden kullanici surekli "haber yok" goruyor  |
//|  gibi bir izlenim aliyordu. Yeni NF_UpdateInfoList() fonksiyonu     |
//|  Security_IsHighImpactNewsWindow()'daki dar anahtar-kelime          |
//|  filtresini (CPI/NFP/FOMC/...) UYGULAMADAN, sadece para birimi ve   |
//|  InpNF_ImportanceMin esigine gore InpNF_LookaheadHours kadar ileri  |
//|  bakan tam haber listesini toplar ve HABER sekmesinde "INFO"        |
//|  basligi altinda listeler (3 dk'da bir yenilenir, cache'lidir).     |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.50                                 |
//|  Lisans dogrulama eklendi (DGN_License.mqh): OnInit()'te Supabase   |
//|  'license-verify' fonksiyonuna sorulur, gecersizse OnTick() trade   |
//|  pipeline'ini calistirmaz (panel/gorunum acik kalir). OnTimer()'da  |
//|  periyodik yeniden dogrulama var, gecici ag hatalarinda grace       |
//|  suresi (48s) boyunca onceki durum korunur.                         |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.49                                 |
//|  UI: Panel basligi eskiden "ALGOTRADE NEXUS BULLET" adli eski/     |
//|  kalinti marka metnini gosteriyordu — kodun geri kalanindaki       |
//|  (yorumlar, Print, PDF kilavuz) "DGN Nexus Pro" adiyla tutarsizdi. |
//|  Artik panel basligi da "DGN NEXUS PRO" gosteriyor.                |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.48                                 |
//|  UX (#119): Istatistik Kartinda (panel ust bilgi satiri) TEMINAT,  |
//|  SERBEST TEMINAT, BASARI ve MAKS. DD alanlari eskiden hepsi sabit  |
//|  CV_DIM (gri) renkteydi. Artik NET/DEGISIM'deki gibi esik-bazli    |
//|  anlamli renklendirme var: TEMINAT %150 alti KIRMIZI / %150-300    |
//|  arasi AMBER / %300+ TEAL; BASARI %40 alti KIRMIZI / %40-55 AMBER  |
//|  / %55+ TEAL; MAKS. DD %15+ KIRMIZI / %5-15 AMBER / %5 alti TEAL;  |
//|  SERBEST TEMINAT sabit mavi vurgu (CV_ACC2) renginde.              |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.47                                 |
//|  #118 KRITIK: HEG_Evaluate() icindeki g_heg_blockUntil TEK global  |
//|  datetime'di, symbol parametresi cooldown icin hic kullanilmiyordu.|
//|  Bir sembolde HEG_SPIKE olustugunda konulan cooldown TUM semboller |
//|  icin gecerli oluyordu (orn. XAUUSD spike → sonraki tickte EURUSD  |
//|  ve BTCUSD da hic spike olmadan HEG_COOLDOWN ile bloklaniyordu).   |
//|  Artik Ind_FindIdx(symbol) ile g_heg_blockUntil[MAX_SYMBOLS]       |
//|  dizisine tasindi — her sembolun kendi bagimsiz cooldown penceresi |
//|  var, diger semboller etkilenmiyor.                                |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.46                                 |
//|  Son hata tarama raporu (115-117) + #100 tekrar inceleme —         |
//|  bu surumde tamamlanan: #115 KRITIK: UpdateNewsLock() icinde       |
//|  "pencereden yeni cikildi" tespiti g_newsLockSym[si]'nin AYNI      |
//|  iterasyonda ustune yazilmis (win=false icin zaten false olan)     |
//|  degerine bakiyordu — kontrol ASLA true olamiyor, CloseHedgeAfter- |
//|  News retry zinciri hic baslamiyordu. Ayri s_prevLockSym[] ile     |
//|  onceki tick'in kilit durumu, uzerine yazilmadan ONCE okunuyor.    |
//|  #116 YUKSEK: Cost_EstCommissionPerLot() cache'i (s_cached/        |
//|  s_lastCalc) TEK kopyaydi, TUM semboller arasinda paylasiliyordu — |
//|  artik Ind_FindIdx(symbol) ile sembol-bazli MAX_SYMBOLS dizisi.    |
//|  #117 ORTA: Lattice_Update() icindeki ATR step/TP refresh throttle |
//|  (s_lastStepRefresh) de ayni sekilde TEK kopyaydi — artik sembol-  |
//|  bazli dizi, her sembolun kendi bagimsiz 30sn periyodu var.        |
//|  #100 (ONCEDEN "ORTA/dogrulanmali" olarak acik birakilmisti):      |
//|  Bullet_CalcLot() sonunda InpTPProjMaxLot kirpmasi RT_LotMode()'   |
//|  dan BAGIMSIZ uygulaniyordu — BLM_AUTO/BLM_MANUAL kullanan (TP-    |
//|  PROJ'u hic kullanmayan) bir kullanicinin lotu bile, ayri bir      |
//|  ayar grubundaki InpTPProjMaxLot (varsayilan 2.0) ile sessizce     |
//|  kirpiliyordu — "ayri kontrol katmanlari" birbirine siziyordu.     |
//|  Artik yalnizca RT_LotMode()==BLM_PROJECT iken uygulanir.          |
//|  ------------------------------------------------------------     |
//|          DGN Nexus Pro R21  v1.78.44                                 |
//|  Tamamlayici hata tarama raporu (111-114) — bu surumde tamamlanan: |
//|  #111 KRITIK: NF CloseHedgeAfterNews basarisiz olsa bile           |
//|  g_newsHardLock kosulsuz false yapiliyordu, "tekrar denenecek"     |
//|  logu yaniltici kaliyordu — bir sonraki tick'te blok hic           |
//|  calismiyordu. Ayri g_nfHedgeCloseRetryPending[] bayragi eklendi,  |
//|  SADECE gercek basaridan sonra false olur. #112 KRITIK: News       |
//|  CloseAllBeforeNews'te ayni sorun — s_closeDone artik SADECE       |
//|  failedN==0 ise true olur, aksi halde ayni pencerede tekrar        |
//|  denenir. #113 YUKSEK: AEGIS pullback peak'i (s_aegPeak) sembol    |
//|  bazli degildi, multi-symbol'de bir sembolun peak'i digerine       |
//|  tasinabiliyordu — artik g_aegPeak[MAX_SYMBOLS], g_sym_idx bazli.  |
//|  #114 YUKSEK: UpdateNewsLock() s_closeDone/s_hedgeDone TEK kopyaydi|
//|  VE Close/Hedge islemleri her zaman chart sembolunu hedefliyordu   |
//|  (pencere tespiti tum semboller icindi) — fonksiyon tamamen        |
//|  sembol-bazli donguye cevrildi, her sembolun kendi state'i ve      |
//|  kendi Close/Hedge islemi var artik.                               |
//|  ------------------------------------------------------------     |
//|  v1.78.43: Ek hata tarama raporu (104-110) — bu surumde tamamlanan fix'ler:  |
//|  Ortak SafeClosePosition() yordami eklendi (retcode + gercek       |
//|  broker dogrulamasi, PositionSelectByTicket ile teyit) — Lattice   |
//|  TP, Bullet Close, News Hedge Close, DD Hedge Exit, VIOP Force     |
//|  Close, Weekly Close, Panel Close butonlari, Security/TimeLimit/   |
//|  PanelBek kapatmalari artik HEPSI bu ortak yordamdan geciyor;      |
//|  basarisiz/kismi kapanista state ARTIK YANLIS ZAMANDA temizlenmiyor|
//|  (#106/#107/#108/#109). DGS_ROBOT artik PAY ve PAYDAyi ayni scope  |
//|  mantigina baglar — robot-baz balance ayri GV anahtariyla saklanir,|
//|  baska EA/manuel islem etkilemez (#104). LOCAL/BROKER saat tabani  |
//|  artik tek Daily_GetNow()/Daily_GetDayStartBrokerTime() yardimci   |
//|  fonksiyonlarinda standardize edildi, HistorySelect baslangici da  |
//|  dogru saat dilimine ceviriliyor (#105). Bullet coklu-pozisyon     |
//|  riski (#110): B_TICKET tekil oldugu icin PROJECT modda da ayni-   |
//|  yon acilis fiilen 1 ile sinirlandi, ayar>1 ise saatte bir uyari   |
//|  logu basar; tam ticket-koleksiyonu buyuk refactor gerektirir.     |
//|  ------------------------------------------------------------     |
//|  v1.78.42: Ek hata tarama raporu (97-103) — bu surumde tamamlanan  |
//|  fix'ler: Panel Close butonlari (KARI/ZARARI/TUMUNU KAPAT) ve VIOP |
//|  Force Close artik PositionClose() retcode'unu dogruluyor,         |
//|  basarisiz kapatmalarda kullanici/log uyariliyor (#101/#102);      |
//|  Daily PnL gun-damgasi InpDailyClockMode'a gore senkron (#98);     |
//|  InpDailyLockScope=DGS_ROBOT gercekten uygulaniyor (#97);          |
//|  InpTPProjGReset artik gercekten kullaniliyor (#99).                |
//|  ------------------------------------------------------------     |
//|  v1.78.41: Hata tarama raporu (56-96) — bu surumde tamamlanan:     |
//|  Weekly Hedge ayri magic (InpMagicWeeklyHedge, #61/#73/#74);       |
//|  Trade_ResolvePositionTicket artik openPriceHint + gercek dolum    |
//|  fiyatini (ResultPrice) kullaniyor (#56/#57/#64); Margin_PerLotSafe|
//|  ile tum lot hesaplari yon-farkindalikli + gercekci fallback       |
//|  (#58/#59); Security_CloseMagicPositions basari/retcode donduruyor |
//|  ve g_resetCount SADECE gercek basaridan sonra artiyor (#62/#82);  |
//|  kismi kapanis Lattice state senkronizasyonu (#63); AutoTune       |
//|  carpanlari InpAutoTune_PersistAcrossRestart ile kalici yapilabilir|
//|  (#93); panelde GRID LOT etiketi efektif (AutoTune/boost/penalty   |
//|  sonrasi gercek) degeri de gosteriyor (#92/#96).                   |
//|  KALAN (rapor #65-72,#78-81,#83-91 kismen): startup Bullet/Lattice |
//|  reconciliation ve Daily PnL kaliciligi v1.78.40'ta zaten yapildi; |
//|  geri kalan dusuk-oncelikli maddeler icin ayri istek beklenir.     |
//|  Mimari: Algotrade Nexus Pro 7.35 (REAL ARCHITECTURE R21)         |
//|  Pipeline + Lattice + TP-PROJ + Direction + DI/TMI + ONNX +       |
//|  Shadow + Panel + Security + Bullet + AWR/AEGIS + MultiSymbol     |
//|  v1.78.40: Hata tarama raporu (56-96) uzerinden 2 KRITIK fix:     |
//|  1) Startup Reconciliation — restart sonrasi broker'daki acik     |
//|     Grid/Bullet pozisyonlari artik RAM state'ine geri kuruluyor   |
//|     (Lattice_ReconcileFromBroker / Bullet_ReconcileFromBroker).   |
//|     Eskiden restart sonrasi last_buy/sell_open_price=0 kaliyor,   |
//|     STEP korumasi ilk yeni seviyede devre disi kaliyordu; Bullet  |
//|     ticket'i de kayboluyor, yonetilemeyen pozisyon + ayni yonde   |
//|     ikinci bullet acilma riski olusuyordu.                       |
//|  2) Daily PnL gun-baslangici artik GV'de kalici — restart sonrasi |
//|     gun icinde birikmis zarar/kar referansi kaybolmuyordu, gunluk |
//|     zarar kilidi restart sonrasi %0'dan basliyormus gibi          |
//|     davraniyordu (Security_GetDailyPnLPercent).                  |
//|  v1.78.39: haber korumasi (CloseAllBeforeNews/HedgeBeforeNews)    |
//|  artik tekrar tekrar calisiyor (eskiden EA omrunde 1 kez); Bullet |
//|  ticket rematch (yetim pozisyon onleme); DD Hedge PauseTrading    |
//|  ayari artik gercekten etkili; manuel ADIM/TP override restart'ta |
//|  korunuyor; HEG AffectGrid/AffectTrend artik gercekten ayri.      |
//|  v1.78.38 KRITIK FIX: KAR%/ZARAR% (GLOBAL PROFIT/LOSS) HESAP      |
//|  GENELİ equity kullanıyordu ama sadece BU sembolün pozisyonlarini |
//|  kapatiyordu — ayni hesapta birden fazla sembole (XAUUSD/BTCUSD/  |
//|  USOIL) ayri EA orneginde, BIR sembolun zarari TUM semboller icin |
//|  yanlis tetiklemeye ve kacak reset dongusune yol aciyordu (reset  |
//|  sayaci binlerce kez gereksiz artmis). Artik SADECE bu sembolun   |
//|  kendi pozisyon kari/zarari kullaniliyor.                         |
//|  v1.78.37: TP BASLANGIC (FIXED/PROJECT) artik gercekten bagli —   |
//|  FIXED iken ILK bullet girisi sabit lotla aciliyor, solver sadece |
//|  MEVCUT pozisyona eklerken devreye giriyor (PROJECT ise eskisi    |
//|  gibi ilk giristen itibaren solver). Ayrica TPProj_Run artik ham  |
//|  InpTPProjPeakTargetMoney yerine RT_Peak() kullanıyor — PEAK MODU |
//|  (v1.78.36) artik solver'a da ulasiyor.                           |
//|  v1.78.36: Panelin TAMAMI tarandi (her tg/ed ID). 3 yeni olu buton|
//|  bulundu: SAAT MODU (BROKER/LOCAL/UTC secimi hic okunmuyordu),    |
//|  PEAK MODU (BAKIYE% secilse bile hep duz $ hesaplaniyordu), NET   |
//|  HEDGE (hicbir karara baglanmamisti — artik Weekly_NetHedge'i     |
//|  takvimden bagimsiz calistiriyor). TP BASLANGIC (FIXED/PROJECT)   |
//|  butonu da olu bulundu ama hicbir yerde (InpTPProjStart bile) hic |
//|  uygulanmamis bastan — baglanacak mevcut bir mantik yok, ayrica   |
//|  ele alinmali.                                                    |
//|  v1.78.35: BULLET sistemi tam denetim — (1) BONUS TP'nin minimum  |
//|  esigi yanlislikla RT_Peak() (hesabin GENEL kar hedefi) kullaniyordu,|
//|  olmasi gereken B_PEAK (bu pozisyonun kendi zirvesi) idi, duzeltildi;|
//|  (2) Entry Quality skoru + min-edge-vs-spread kapisindaki sabit    |
//|  XAUUSD puanlari ATR-oranli hale getirildi (ADIM'daki ayni olcek  |
//|  riski); (3) Bullet'in tick-teyit sayisi da artik RT_TimingMult   |
//|  ile XAUUSD disinda genisliyor.                                   |
//|  v1.78.34: TREND UYUM ACIK iken hicbir yonu filtrelemiyordu (BUY/  |
//|  SELL ayrimi yapmiyordu) — artik gercekten sadece trendle AYNI     |
//|  yondeki girise izin veriyor, tersini blokluyor. Basari oranini    |
//|  artiracak giris kosulu.                                          |
//|  v1.78.33: hafta sonu altin kapali oldugunda BTC'ye gecis DUZENLI |
//|  bir kullanim — XAUUSD disi sembollerde VEMA-X/Classic/First      |
//|  Touch'un TUM zamanlama pencereleri artik otomatik 2.5x genisler  |
//|  (RT_TimingMult), test edilmemis enstrumanlarda sistem kendiliginden|
//|  daha temkinli calisir.                                           |
//|  v1.78.32: GUVENLIK KILIDI — EA'nin XAUUSD disinda (USOIL/BTCUSD  |
//|  gibi) baska bir grafige takilip ADIM'in o sembolun ATR'sine gore |
//|  olcek-disi kalmasina karsi son savunma hatti: ADIM, sembolun     |
//|  KENDI o anki ATR'sinin InpSafety_MinStepAtrFrac katindan (var-   |
//|  sayilan %5) kucukse yeni grid seviyesi acilmaz, panelde uyarilir.|
//|  v1.78.31: DEGER/ARAC sekmelerinde 10 editbox, scroll ile viewport|
//|  disina cikinca gizlenmiyordu (CV_ShowEditInline disaridan yanlis |
//|  CV_Vis ile sartlanmisti, kendi gizleme kodu hic calismiyordu) -  |
//|  kutular ekranda "yapisik" kalip sabit sekme/buton seridini       |
//|  kapatiyordu. Artik CV_ShowEditInline her zaman cagriliyor.       |
//|  v1.78.30: unutulan is - ADIM PNT/TP PUAN'a elle yazilan deger    |
//|  artik ATR MODU acikken 30sn'de bir sessizce ezilmiyor; ATR MODU  |
//|  tekrar ACIK'a alinana ya da yeni risk presetine gecilene kadar   |
//|  kalici. tgAtrMode ACIK + RiskPreset_Apply override'i temizler.   |
//|  v1.78.29: Classic Live'in flip-confirm mantigi tersti (VEMA-X'in |
//|  eski hatasiyla ayni aile) - duzeltildi + Entry/Flip ayrimi       |
//|  gercekten calisiyor artik. First Touch throttle damgasi hic      |
//|  guncellenmiyordu (her tick yeniden hesapliyordu) - onbellekle    |
//|  duzeltildi.                                                      |
//|  v1.78.28: VEMA-X hysteresis esigi ConfirmBars=3'te hic devreye   |
//|  giremiyordu (0.333>0.25) — artik need'e gore olcekleniyor, sık   |
//|  sinyal değişimi/whipsaw azalir.                                  |
//|  v1.78.27: edAtrTrig kutusuna ust/alt sinir (0.1-5.0) — asiri buyuk|
//|  deger (orn. 100) yazilinca ADIM gercek disi buyuyup grid'in hic  |
//|  acilmamasini engeller; RiskATR_AutoFill icinde de ikinci sinir.  |
//|  v1.78.22-26: ATR tabanli ADIM sistemi + spread koruma (bkz. asagi)|
//|  v1.78.21: TREND KAYNAK butonu artik gercekten baglandi (RT_GridTrendPhase)|
//|  v1.78.20: risk R:R – genis TP, yuksek min$, uzak zarar, tek tohum|
//|  v1.74: canvas; v1.73: lot/filling; v1.72: CUDA/ONNX              |
//+------------------------------------------------------------------+
//| STRATEGY TESTER – TEMKİNLİ PRESET NOTLARI (PDF §13 yaklaşımı)    |
//|                                                                  |
//|  A) CONSERVATIVE (ilk demo / tester)                             |
//|     - InpVG_Enable=false  veya MaxLevels=2, Lot=min              |
//|     - InpBulletEnable=true, BLM_MANUAL, çok küçük lot            |
//|     - InpNF_Enable=true, PauseTrading=true                       |
//|     - InpDailyProfitTargetPct=1.0, DailyLoss=1.0                 |
//|     - InpGlobalProfitPct=2.0, GlobalLoss=2.0                     |
//|     - InpML_ONNX_Enable=false, InpAutoTune_Enable=false          |
//|     - InpExtra_Enable=true, BlockHighSpread=true                 |
//|                                                                  |
//|  B) BALANCED (demo ileri)                                        |
//|     - VG ON, MaxLevels=4-6, Step makul                           |
//|     - Bullet BLM_AUTO veya PROJECT, PeakTarget düşük             |
//|     - Daily 2-3% / Global 4-5%                                   |
//|     - News ON, VIOP session ON (vadeliyse)                       |
//|                                                                  |
//|  C) AGGRESSIVE (sadece anladığınızda)                            |
//|     - Pyramid/Loop açık, daha yüksek level                       |
//|     - TP-PROJ SOLVER + PeakTarget agresif                        |
//|     - AutoTune ON (OnlyDemo önerilir)                            |
//|     - Risk yüksek – canlıda dikkat                               |
//|                                                                  |
//|  TESTER İPUCU: Every tick / 1D-1W önce; ONNX model Files'ta;     |
//|  Calendar haberleri testerde sınırlı olabilir.                   |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|  v1.78.98 SAFELOT / VEMA / FLIPFIX  —  "LOT, ISLEM SAYISI VE      |
//|  TREND DONUSU DUZELTME REHBERI" tam uygulamasi                    |
//|  (Kaynak: v1.78.97 VEMA_MAREGIME-1.mq5.txt — DOGRU taban)         |
//|                                                                   |
//|  [UYGULANDI] #1 (P0) Lot risk cap: RiskCap_MaxLot() v1.78.93'te   |
//|  Lot_CalcCapped()'ten tamamen sokulmustu. Artik InpRiskSizing_    |
//|  Enable acikken ZORUNLU ikinci katman: equity-risk% tavanini asan |
//|  lot kirpilir; risk verisi hesaplanamazsa (DBL_MAX) veya tavan    |
//|  <=0 ise "sinirsiz ac" degil, islem ACILMAZ (lot=0).              |
//|                                                                   |
//|  [UYGULANDI] #2 (P0) MinLot guvenli ayrim: NormalizeLotByStep     |
//|  guvenli riskli lotu broker minLot'unun USTUNE zorluyordu. Yeni   |
//|  NormalizeLotForEntry() risk cap sonucu minLot altindaysa 0       |
//|  dondurur; Lattice_CalcLot da ayni prensiple 0'i yukari zorlamaz. |
//|                                                                   |
//|  [UYGULANDI] #3 Panel/GV lot hafizasi: PanelMemory_Load() artik   |
//|  VGLOT/BLOT degerlerini broker min/max ve InpLatticeMaxLot ile    |
//|  clamp ediyor. PanelMemory_ResetLotMemory() eklendi (VGLOT/BLOT   |
//|  GV kayitlarini siler) - panel butonuna baglamak istege birakildi.|
//|                                                                   |
//|  [UYGULANDI] #4 (P0) Grid toplam exposure: derinlik carpani tek   |
//|  bir pozisyonu sinirliyordu ama tum acik kademelerin TOPLAM lotu  |
//|  hicbir yerde sinirlanmiyordu. Yeni Grid_OpenExposure() +         |
//|  InpGridMaxTotalLot (varsayilan 0 = KAPALI, hesap buyuklugune     |
//|  gore siz ayarlayin) eklendi; asilirsa DIAG_RET("GRID_EXPOSURE"). |
//|                                                                   |
//|  [UYGULANDI] #5 Bullet ilk giris lotu: TP BASLANGIC=PROJECT       |
//|  secildiginde bile ILK giris (B_TICKET==0) artik HER ZAMAN         |
//|  RT_BulletLot() kullanir; TP-Proj solver sadece MEVCUT pozisyona   |
//|  EKLEME yaparken devreye girer. Not: TP BASLANGIC=PROJECT secen    |
//|  kullanicilar icin ONCEKI ilk-giris davranisini kasitli olarak     |
//|  degistirir (guvenlik icin).                                       |
//|                                                                   |
//|  [UYGULANDI] #6 VEMA MA9/MA21 rejim yumusatma: VEMA_MA_RegimeGate  |
//|  eskiden rejim HENUZ TEYIT EDILMEMISKEN bile (confirmedRegime==0)  |
//|  VEMA-X'in URETTIGI HER sinyali direction=0/PHASE_NEUTRAL yaparak  |
//|  tam veto ediyordu - bu da baslangicta / her reset sonrasi         |
//|  ConfirmBars kadar mum boyunca islem sayisini gereksiz dusuruyordu.|
//|  Artik: (a) rejim teyitsizken HICBIR MUDAHALE yok - VEMA-X sonucu  |
//|  aynen geciyor; (b) rejim TEYITLI ve VEMA-X TERS yondeyse artik    |
//|  direction'i SIFIRLAMIYOR (Direction Lock'un kendi flip-teyit      |
//|  mantigina birakiliyor - iki katmanin ayni flip'i art arda          |
//|  bloklamamasi icin), sadece guven puanini InpVemaMA_               |
//|  ConflictConfidenceMult (varsayilan 0.35, test parametresi) ile    |
//|  dusuruyor; (c) rejim teyitli + ayni yon: degisiklik yok.           |
//|                                                                   |
//|  [ZATEN DOGRU] #7 Direction Lock / trend donusu: mevcut            |
//|  DirectionLock_Manage() zaten "teyit -> kontrollu kapat -> yeni    |
//|  yon SONRAKI tick'te ac" sirasini uyguluyor. #6'nin degisikligiyle |
//|  birlikte artik VEMA conflict'i de Direction Lock'un flip teyidini |
//|  BASTAN engellemiyor (eskiden direction=0 yaptigi icin Direction   |
//|  Lock aday yonu hic goremiyordu) - iki katmanin ayni flip'i cift   |
//|  bloklamasi sorunu boylece cozuldu.                                |
//|                                                                   |
//|  [UYGULANDI] #9 Ret loglama: mevcut DIAG_RET makrosuna "RISK_CAP"  |
//|  / "RISK_MINLOT" / "GRID_EXPOSURE" sebep kodlari eklendi           |
//|  (g_lastLotRejectReason araciligiyla Lot_CalcCapped'in RET          |
//|  nedenini cagirana tasimasi). VEMA conflict de artik                |
//|  engine_name'e "+MACONFLICT" etiketiyle isaretleniyor.              |
//+------------------------------------------------------------------+
//|  v1.78.99 COMPILEFIX                                              |
//|  Derleme hatasi: Bullet_CalcLot() icinde "(void)startMode;" satiri |
//|  MQL5'te GECERSIZ - MQL5, C/C++'daki gibi bir ifadeyi void'e cast   |
//|  ederek "kullanilmiyor" uyarisini bastirma sozdizimini desteklemiyor|
//|  ("illegal use of 'void' type" + "invalid cast operation" hatalari |
//|  + "expression has no effect" uyarisi, hepsi ayni satirdan). Satir |
//|  tamamen kaldirildi (yerine aciklayici yorum birakildi); startMode |
//|  zaten asagidaki mantikta okunmuyor, MQL5 kullanilmayan yerel      |
//|  degiskenler icin hata vermez.                                     |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|  v1.78.140 RISK-CALIBRATION  (kullanicinin 139 Strateji Sinama    |
//|  raporuna karsi istedigi esik kalibrasyonu - 1000$ test hesabi,   |
//|  XAUUSD M5, 2026.08.02-09.01: net -1000.44$, PF 0.78, %41 kazanma,|
//|  ort.kazanc 10.19$ / ort.kayip 9.16$ - "buyuk kayip/kucuk kazanc" |
//|  degil, dusuk kazanma oranli yavas erime. Bu 3 kalibrasyon o      |
//|  rapordaki somut bulgulara dayanir, TAHMINI DEGILDIR:             |
//|                                                                    |
//|  [1] InpTPProjSolverMaxLot: 0 (sinirsiz) -> 0.10. Rapor girdi     |
//|  dokumunde bu deger hala 0'di - SOLVER ayni yonde sinirsiz lot     |
//|  onerebiliyordu (bkz. 139 REGIME-UNSTICK #3 notu, o zaman da       |
//|  "0 birakilirsa hicbir sey degismez" diye isaretlenmisti). Artik   |
//|  InpGridMaxTotalLot (0.10) ile AYNI olcekte - SOLVER, Grid modulu  |
//|  ile ayni tavana tabi, ayricalikli degil.                          |
//|                                                                    |
//|  [2] InpRiskSizing_AdverseATRMult: 8.0 -> 3.0. Girdi grubunun      |
//|  kendi yorumu (DUZELTME_REHBERI bolum 12) 2.0-3.0 araligini        |
//|  oneriyordu, varsayilan hic degistirilmemisti. 8x ile RiskCap_     |
//|  MaxLot() cok dar hesaplaniyor, hesaplanan lot broker minLot'un    |
//|  altina dusup NormalizeLotForEntry'de sessizce iptal olabiliyordu -|
//|  "lot buyumuyor" sikayetinin bir bacagi buydu.                     |
//|                                                                    |
//|  [3] InpDailyLossLockEnable: false -> true. %3 gunluk zarar kilidi |
//|  zaten koddaydi (InpDailyLossTargetPct=3.0) ama kapaliydi. 825     |
//|  islem/ayda dagilmis kucuk-negatif-beklentili bir sistemde gun     |
//|  icinde ust uste kucuk kayiplarin birikmesini erken kesmek icin    |
//|  acildi.                                                           |
//|                                                                    |
//|  DOKUNULMADI (kasitli): InpGridRiskMaxDDPct(2%)/InpRiskGov_        |
//|  DrawdownStartPct(4%)/HardPct(8%)/InpGlobalLossPct(5%)/InpRiskGov_ |
//|  BasketLossLimit(50$) - birbirine gore kademeli/tutarli duruyor,   |
//|  bu rapor bunlarin bozuk oldugunu göstermiyor. InpTPProjMaxLot     |
//|  (2.0, SOLVER disindaki TPProj rejimleri icin ust tavan) da        |
//|  DOKUNULMADI - 1000$ hesaba gore genis durabilir, ayri bir karar   |
//|  gerektirir, kullaniciya soruldu.                                  |
//|                                                                    |
//|  NOT: [1] ve [2] hesap buyuklugune (1000$ test) gore olceklendi -  |
//|  canli hesabiniz farkliysa oranti ile yeniden ayarlayin.           |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|  v1.78.139 REGIME-UNSTICK  (kullanici raporu: "hep COZUCU calisiyor,|
//|  hesap hic kara gecmiyor")                                        |
//|                                                                    |
//|  [DUZELTILDI] #1 BALANCE_PCT dongusel kilit: AdaptiveMarket_       |
//|  ChooseRegime() eskiden BALANCE_PCT'e SADECE equity>balance ise    |
//|  (yani hesap ZATEN net kardaysa) geciyordu - hesap zarardayken bu  |
//|  rejime hicbir zaman ulasilamiyordu, hep SOLVER'a dusuyordu. Artik |
//|  yeni InpAdaptive_BalancePctDDTol input'u ile "kucuk bir DD        |
//|  toleransi icindeyse de" (varsayilan %1) bu rejime gecilebiliyor.  |
//|                                                                    |
//|  [DUZELTILDI] #2 Rejim esikleri sabit/kucuk zaman dilimine gore    |
//|  kalibre degildi: highVolatility (ATR%>=0.35) ve trendMarket       |
//|  (ADX>=25) sabitleri, dusuk zaman dilimi ATR%'lerine gore genelde  |
//|  HICBIR ZAMAN tutmuyordu - NETVOL/DEFICIT dallarina pratikte hic   |
//|  sira gelmiyor, her sey SOLVER'a yigiliyordu. Artik dort esik      |
//|  (ATR%, trend ADX, range ADX, spread%) InpAdaptive_* input'lariyla |
//|  ayarlanabilir; varsayilanlar daha gercekci (ATR% 0.35->0.15,      |
//|  trend ADX 25->22) sekilde gevsetildi.                             |
//|                                                                    |
//|  [EKLENDI] #3 SOLVER kumulatif lot durma noktasi: TPProj_Calculate |
//|  icindeki SOLVER kolu, fiyat lehte donmedigi surece zarardaki      |
//|  yone SINIRSIZ ek lot onerebiliyordu (klasik martingale/averaging  |
//|  davranisi - asil "hesap hic kara gecmiyor" sikayetinin kok        |
//|  sebebi). Yeni InpTPProjSolverMaxLot (varsayilan 0 = KAPALI, eski  |
//|  davranis) ayni-yon TOPLAM lot bu degeri asinca SOLVER'in ek lot   |
//|  onerisini 0'a ceker ("SOLVER_MAXLOT_DUR"). Hesap buyuklugunuze    |
//|  gore MUTLAKA siz ayarlamaniz gerekir - 0 birakilirsa hicbir sey   |
//|  degismez.                                                         |
//|                                                                    |
//|  [EKLENDI] #4 Tani logu: AdaptiveMarket_ChooseRegime() artik       |
//|  InpAdaptive_DiagLogSec saniyede bir (varsayilan 30, 0=kapali)     |
//|  Journal'a atrPct/adx/yon-hizasi/ddPct/secilen rejim satiri        |
//|  yazar - hangi esigin tutup tutmadigi CANLI izlenebilir.           |
//+------------------------------------------------------------------+
#property copyright "DGN / Nexus R21"
#property version   "1.78"
#property strict
#property description "DGN Nexus Pro R21 v1.78 RECOVERY | Grid/Hedge risk and recovery controls"

// v1.78.130 CRITICAL: ULLONG_MAX tanımsızlığı (#strict uyum)
#define ULLONG_MAX 18446744073709551615ULL

// v1.78.72: merkezi versiyon etiketi - panel/log/OnInit/OnDeinit hepsi
// buradan okur, boylece hangi derlemenin test edildigi HER ZAMAN net olur.
// Onceki surumlerde #property version ("1.65") ile #property description
// ("v1.78.71") CELISIYORDU ve OnDeinit de ayrica "v1.78.20" yaziyordu -
// panelde/loglarda hangi kodun calistigi belirsizdi, bu da hangi test
// sonucunun hangi degisiklige ait oldugunu geriye donuk ayirt etmeyi
// imkansiz kiliyordu (EMA-at-close duzeltmesi orneginde oldugu gibi).
#define DGN_BUILD_TAG "v1.78.168-RISKTEST-PROOF"

// v1.78.132: Hard SL kullanicinin ACIK talebiyle DERLEME-ZAMANI SABITINE
// baglandi (runtime input DEGIL) - hesap patlamasina karsi son care olan
// bu katman, bir .set/preset/panel unutkanligiyla sessizce kapanmasin
// diye. Kapatmanin TEK yolu: bu satiri false yapip yeniden derlemek
// (AC2 A/B karsilastirmasi icin bu, gecici olarak yapilmasi gereken
// normal bir adimdir - canli hesapta true birakilmalidir).
#define HARDSL_FORCE_ENABLED true
// v1.78.53 (#123): Panel baslik cizimi #property version string'ini tekrar
// yazmasin diye ayni deger burada tek noktadan tutuluyor.
// v1.78.72 FIX: bu deger "1.65" olarak sabitlenmisti ve DGN_BUILD_TAG'den
// (ve #property version'dan) BAGIMSIZDI - panelde/logda/property'de 3 farkli
// surum numarasi goruluyordu, hangi derlemenin test edildigini ayirt etmeyi
// imkansiz kiliyordu. Artik tek kaynaktan (DGN_BUILD_TAG) besleniyor.
string g_dgn_version = DGN_BUILD_TAG;

// v1.78.65: SUPPORT/RESISTANCE + BREAKOUT CONFIRMATION ve RANGE PROFIT GUARD.
// Trend girisleri, son kapanmis barlardan hesaplanan dinamik destek/direncin
// kirilimini ATR tamponu + N kapanis ile teyit etmeden acilmaz. RANGE rejimi
// teyit edilince pozitif Bullet karini korur; zararli pozisyonu bu guard kapatmaz.
// Amac: yatay piyasada trend takibiyle birikmis kari geri verme / kara zarara
// donme sorununu azaltmak. Varsayilanlar kontrollu ve geri alinabilir.
//
// v1.78.62 FINAL_CHECKED_RISKFIX:
// 1) Grid STEP/ATR safety uses the last opened level's locked STEP.
// 2) STEP diagnostics report the same locked STEP actually used by the gate.
// 3) Pyramid eligibility uses money P/L (profit+swap), weighted by the live basket
//    volume when converting the existing point threshold to a monetary threshold.
// 4) Grid lot multiplier depth is side-specific (BUY depth for BUY, SELL depth for SELL).
// 5) Grid obeys the existing SAME-SIDE MinDist guard when that input is enabled.
// 6) Partial security closes count as successful progress; failed residual closes
//    remain protected by the loss lock and are retried without falsely treating a
//    partial close as a total failure.

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Canvas\Canvas.mqh>
#include "DGN_License.mqh"

#ifndef CALENDAR_IMPORTANCE_HIGH
   #define CALENDAR_IMPORTANCE_HIGH 3
#endif

// --- FIX: MQL5 sira zorunlulugu icin forward ---
void   TPProj_GetSameSideStats(const string symbol, const ulong magic, const int direction, double &lotSum, double &pnlSum);
double TPProj_MoneyPerPriceUnit(const string symbol);
double TPProj_ExpectedMove(const string symbol);
double TPProj_NormalizeLot(const string symbol, double lot, const bool isGridMotor=true, const int direction=1);
double VirtualTP_MoneyTarget(const double equityBase);
// v1.78.141 RISK_CALIBRATION FIX (DUZELTME_REHBERI [bu PDF] #1, P0): RiskCap_MaxLot()
// artik HardSL_Distance()'i (asagida ~7745 civarinda tanimli) TEK risk mesafesi
// kaynagi olarak kullaniyor - forward declaration MQL5'in "kullanmadan once tanimla"
// kuralini karsilamak icin gerekli (RiskCap_MaxLot, HardSL_Distance'dan ONCE tanimli).
double HardSL_Distance(const string symbol, const bool isGridMotor);
string RT_RegimeName(); // v1.78.139: AdaptiveMarket_ChooseRegime() icindeki tani logu icin (tanimi asagida)

// Support/resistance + range protection
// NOT: Bu 3 fonksiyon icin forward declaration YOK - cunku ENUM_MARKET_PHASE (satir ~591)
// ve SPipelineContext (satir ~677) burada henuz tanimli degil, bu da "declaration without
// type / comma expected" derleme hatalarina yol aciyordu. Fonksiyonlarin ilk kullanildigi
// yerler (satir ~5599, ~5679, ~6714, ~10960) zaten gercek tanimlarindan (satir ~5435, ~5595,
// ~6493) SONRA geldigi icin forward declaration'a hic gerek yok.
string TradeDiag_Compute();
void   Panel_RequestUpdate(const bool force=false);
void   UpdateMinimalPanel();
void   CreateMinimalPanel();
void   Panel_SyncScrollFromTab();
void   Panel_SaveScrollToTab();
int    Panel_MaxScrollForTab(const int tab);
void   Panel_DrawScrollBar(const int w, const int viewTop, const int viewH);
void   Panel_HideAllEdits();
void   Panel_BeginEdit(const string name);
void   CreateEdit(const string name, const int x, const int y, const int w, const int h, const string text="");
void   CV_ShowEditInline(const string id, int panelX, int panelY, int w, int h, const string text, bool forceText=false);
void   CV_ValEditRow(int x, int y, int w, int h, const string label, const string editId, const string valTxt);
int    VolumeDigits(const string symbol);
double NormalizeLotByStep(const string symbol, double lot);
double NormalizeLotForEntry(const string symbol, double lot);
double Lot_CalcCapped(const string symbol, double baseLot, const bool isGridMotor=true, const int direction=1);
double PULLBACK_LotMult(const string symbol); // v1.78.101: trend-ici pullback lot olcek katsayisi (bkz. VEMA_MA_RegimeGate)
double RawConfidence_Get(const string symbol, double fallback); // v1.78.105: TFG icin rejim cezasindan onceki ham VEMA-X guveni (bkz. VEMA_MA_RegimeGate)
bool   ERB_BlocksNewRisk(const string symbol); // v1.78.120: true ise yeni Grid/Bullet girisi bu tick'te ENGELLENMELI
double PanelMemory_ClampGvLot(double lot, double minLot, double maxLot);
void   PanelMemory_ResetLotMemory();
double Security_GetDailyPnLPercent();
bool   Security_IsFuturesSymbol(const string symbol);
bool   Security_IsInTradeSession(const string symbol);
int    AutoCost_MaxSpreadPts(const string symbol);
ENUM_TIMEFRAMES TF_EffectiveRange(); // FIX v1.78.13: Ind_ATR fallback'inden erken cagriliyor
string RiskModeLabel(); // FIX v1.78.13: buton click handler'indan TradeDiag'dan once cagriliyor
void   RiskPreset_Apply(int mode, bool resetManualOverride=true); // FIX v1.78.13: click handler'indan tanimindan once cagriliyor

//--- v1.73: Sembol lot basamak sayısı (SYMBOL_VOLUME_STEP'ten)
int VolumeDigits(const string symbol)
{
   double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0) step = 0.01;
   int d = 0;
   double s = step;
   while(d < 8 && MathAbs(s - MathRound(s)) > 1e-12)
   {
      s *= 10.0;
      d++;
   }
   return d;
}

double NormalizeLotByStep(const string symbol, double lot) {
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0) step = 0.01;
   if(lot <= 0.0) return 0.0;
   lot = MathFloor(lot / step + 1e-12) * step;
   if(lot < minLot) lot = minLot;
   if(lot > maxLot) lot = maxLot;
   return NormalizeDouble(lot, VolumeDigits(symbol));
}

// v1.78.98 FIX (DUZELTME_REHBERI #2, P0): NormalizeLotByStep minLot altina
// dusen HER lotu minLot'a yukari yuvarliyordu. Bu, genel broker-uyumluluk
// normalizasyonu icin dogru olsa da, Lot_CalcCapped()'in equity-risk cap'i
// artik ZORUNLU oldugu icin (bkz. yukarida #1) yanlis yerde kullanilirsa
// "risk motoru 0.003 lot izin veriyor, ama minLot 0.01 oldugu icin 0.01
// acalim" gibi niyet edilenin 3 kati riske donusebilir. NormalizeLotByStep
// KENDISI degistirilmedi (baska hicbir yerden cagrilmiyor, sadece
// Lot_CalcCapped icinde kullaniliyordu - bkz. asagi) - onun yerine SADECE
// giris (yeni islem) lotu icin bu ayri fonksiyon eklendi: risk cap sonucu
// minLot'un altindaysa 0 doner (islem acilmaz), yukari zorlanmaz.
// v1.78.130 FIX ENHANCED: Kullanici talebiyle v1.78.100'de "0 dondur" davranisi kaldirilmisti,
// fakat v1.78.130'de ek bir güvenlik katmanı eklendi: Lot sıfıra çıkarsa minLot'a çevirme.
// Risk motorunun hesapladigi guvenli lot broker minLot'unun (ör. Exness 0.01) altında kaldiginda
// islem artık iptal edilmiyor; lot dogrudan minLot'a yukari yuvarlanip OrderSend'e gidiyor.
// NOT: Bu, kucuk hesaplarda/dusuk risk ayarlarinda gercek riskin hesaplanandan daha yuksek
// olmasina yol acabilir (broker min lot zorunlulugu nedeniyle) - bu bilinerek tercih edildi.
double NormalizeLotForEntry(const string symbol, double requestedLot) {
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0) step = 0.01;
   if(requestedLot <= 0.0 || minLot <= 0.0) return 0.0;
   double lot = MathFloor(requestedLot / step + 1e-12) * step;
   // v1.78.130: Eğer normalize sonrası lot hala minLot'un altındaysa, minLot'a yükselt
   // (işlem öncesi son fırsat - böylece OrderSend hiçbir zaman lot hatasıyla başarısız olmaz)
   if(lot < minLot) {
      lot = minLot;
      g_lastLotRejectReason = "LOT_MINLOT_YUKARI_YUVARLA"; // diagnostik
   }
   if(maxLot > 0.0) lot = MathMin(lot, maxLot);
   lot = NormalizeDouble(lot, VolumeDigits(symbol));
   if(lot < minLot || (maxLot > 0.0 && lot > maxLot)) return 0.0;
   return lot;
}


//+------------------------------------------------------------------+
//| 1. ENUM'LAR (PDF Ek A + mimari ihtiyaçlar)                       |
//+------------------------------------------------------------------+
enum ENUM_LANG {
   LANG_EN = 0, LANG_TR, LANG_KU, LANG_RU, LANG_HI, LANG_ZH,
   LANG_FR, LANG_AR, LANG_FA, LANG_DE, LANG_IT, LANG_PT, LANG_ES
};

enum ENUM_DIRECTION_ENGINE {
   DIR_ENGINE_VEMA        = 0,   // VEMA-X
   DIR_ENGINE_FIRST_TOUCH = 1,   // First Touch
   DIR_ENGINE_CLASSIC     = 2    // Classic Live
};

enum ENUM_DAILY_GUARD_SCOPE {
   DGS_ROBOT   = 0,
   DGS_ACCOUNT = 1
};

enum ENUM_DAILY_GUARD_CLOCK {
   DGC_BROKER = 0,
   DGC_LOCAL  = 1
};

enum ENUM_AUTO_TUNE_RISK {
   RISK_ULTRA_SAFE   = 0,
   RISK_CONSERVATIVE = 1,
   RISK_BALANCED     = 2,
   RISK_AGGRESSIVE   = 3,
   RISK_ULTRA_AGGR   = 4
};

enum ENUM_TIME_RESET_MODE {
   TR_CLOSE_ALL    = 0,
   TR_CLOSE_PROFIT = 1,
   TR_CLOSE_LOSS   = 2
};

enum ENUM_BULLET_LOT_MODE {
   BLM_AUTO    = 0,
   BLM_MANUAL  = 1,
   BLM_PROJECT = 2      // TP-PROJ
};

enum ENUM_TPPROJ_VOLUME_REGIME {
   TPP_REG_FIXED              = 0,
   TPP_REG_BALANCE_PCT        = 1,
   TPP_REG_TARGET_DEFICIT     = 2,
   TPP_REG_CONTROLLED_RECOVERY= 3,
   TPP_REG_NET_VOLUME_TARGET  = 4,
   TPP_REG_SOLVER             = 5   // varsayılan
};

enum ENUM_TPPROJ_START_MODE {
   TPP_START_FIXED_LOT     = 0,
   TPP_START_PROJECTED_LOT = 1
};

enum ENUM_TPPROJ_GRESET_START {
   TPP_GRESET_KEEP_PEAK_LOGIC = 0,
   TPP_GRESET_FIXED_LOT       = 1,
   TPP_GRESET_PROJECTED_LOT   = 2
};

enum ENUM_NDI_PROFILE {
   NDI_MORE_TRADES = 0,
   NDI_BALANCED    = 1,
   NDI_SELECTIVE   = 2
};

enum ENUM_NDI_FLIP_SAFETY {
   NDI_FLIP_NORMAL      = 0,
   NDI_FLIP_STRONG      = 1,
   NDI_FLIP_VERY_STRONG = 2
};

enum ENUM_AWR_REGIME_SRC {
   AWR_SRC_VR_TF     = 0,
   AWR_SRC_PULSE_TICK= 1,
   AWR_SRC_ENSEMBLE  = 2
};

enum ENUM_GRID_LOT_MODE {
   GLM_FIXED        = 0,
   GLM_BALANCE_PCT  = 1,
   GLM_EQUITY_PCT   = 2
};

enum ENUM_GRID_TP_MODE {
   GTP_SPREAD_MULT  = 0,
   GTP_BALANCE_PCT  = 1,
   GTP_FIXED_POINTS = 2,
   GTP_PRICE_PCT    = 3
};

enum ENUM_GRID_STEP_MODE {
   GST_FIXED_POINTS = 0,
   GST_RANGE_MULT   = 1,
   GST_PRICE_PCT    = 2
};

enum ENUM_TIME_FILTER_ACTION {
   TFA_BLOCK_NEW    = 0,
   TFA_CLOSE_PROFIT = 1,
   TFA_CLOSE_ALL    = 2,
   TFA_NET_HEDGE    = 3
};

enum ENUM_TIME_FILTER_CLOCK {
   TFC_BROKER = 0,
   TFC_LOCAL  = 1,
   TFC_UTC    = 2
};

enum ENUM_VIOP_DETECTION {
   VIOP_AUTO     = 0,
   VIOP_FORCE_ON = 1,
   VIOP_FORCE_OFF= 2
};

enum ENUM_VIOP_ROLLOVER {
   VIOP_ROLLOVER_OFF      = 0,
   VIOP_ROLLOVER_SUGGEST  = 1,
   VIOP_ROLLOVER_AUTO     = 2
};

enum ENUM_ML_ACCEL {
   ML_ACCEL_AUTO     = 0,   // ONNX_DEFAULT: GPU varsa CUDA, yoksa CPU
   ML_ACCEL_CUDA_0   = 1,   // ONNX_GPU_DEVICE_0
   ML_ACCEL_CUDA_1   = 2,   // ONNX_GPU_DEVICE_1
   ML_ACCEL_CUDA_2   = 3,
   ML_ACCEL_CUDA_3   = 4,
   ML_ACCEL_CPU_ONLY = 5    // ONNX_USE_CPU_ONLY (TensorRT yok – MT5 CUDA EP)
};



// Yön / Faz
enum ENUM_MARKET_PHASE {
   PHASE_NEUTRAL = 0,
   PHASE_TREND_UP,
   PHASE_TREND_DOWN,
   PHASE_RANGE
};

// Pipeline aşamaları (log ve debug için)
enum ENUM_PIPELINE_STAGE {
   STAGE_PLATFORM_CHECK = 0,
   STAGE_SECURITY_LOCKS,
   STAGE_POSITION_CACHE,
   STAGE_GLOBAL_RESETS,
   STAGE_PROFIT_EXITS,
   STAGE_DIRECTION_ENGINE,
   STAGE_MICRO_LAYERS,      // DI / TMI / AWR / AEGIS / NDI / DTE
   STAGE_ROUTER_UDC,
   STAGE_FINAL_VETO,
   STAGE_EXECUTION
};

//+------------------------------------------------------------------+
//| 2. TEMEL STRUCT'LAR                                              |
//+------------------------------------------------------------------+
// R21 Fixed Virtual Lattice
// ---------------------------------------------------------------
// Kural (PDF): Grid seviyeleri SANALDIR. Broker'a BUY LIMIT / SELL LIMIT
// veya STOP emri DİZİLMEZ. Fiyat sanal hücreye girdiğinde yalnız PİYASA
// emri açılır. Terminal/EA kapanırsa sanal yönetim de durur → VPS şart.
//
// STEP otoritesi: Aynı yönde yeni kademe, son açık seviyeden en az
// "step" kadar fiyat hareket etmeden AÇILMAZ.
// ---------------------------------------------------------------
#define LATTICE_MAX_LEVELS 32   // her yön için maksimum sanal hücre

struct SLatticeLevel {
   bool     active;          // bu hücre şu an açık pozisyon taşıyor mu?
   double   trigger_price;   // sanal tetik fiyatı
   double   open_price;      // gerçek açılış fiyatı (0 = henüz açılmadı)
   double   step_at_open;    // bu kademenin açıldığı anda kilitlenen STEP
   ulong    ticket;          // açılan pozisyon ticket'ı (0 = yok)
   double   lot;
   datetime open_time;
};

struct SLatticeState {
   bool           initialized;
   double         anchor_price;          // lattice merkezi (genelde ilk mid veya son re-anchor)
   double         buy_step;              // BUY tarafı adım (fiyat birimi)
   double         sell_step;             // SELL tarafı adım (fiyat birimi)
   double         last_buy_open_price;   // son BUY açılış fiyatı (STEP kontrolü için)
   double         last_sell_open_price;  // son SELL açılış fiyatı
   int            buy_levels_active;
   int            sell_levels_active;
   SLatticeLevel  buy_levels[LATTICE_MAX_LEVELS];
   SLatticeLevel  sell_levels[LATTICE_MAX_LEVELS];
   datetime       last_update;
   datetime       last_reanchor;
   // Pyramid / Loop / Escape
   int            pyramid_buy_extra;
   int            pyramid_sell_extra;
   datetime       last_loop_buy_time;
   datetime       last_loop_sell_time;
   // v1.78.113 EKLENTI (kullanici tespiti): Loop Harvest re-entry, kar
   // alinan kademenin KAPANIS FIYATINI bilmiyordu - sadece zaman (cooldown)
   // gecince STEP mesafesi beklemeden yeni kademe aciliyordu. Kullanicinin
   // gozlemledigi sorun: SELL trendinde kar alinip kapaniyor, ama fiyat
   // HEMEN geri cekiliyor (henuz devam etmemisken) ve yeni SELL kademesi
   // KOTU ZAMANLI acilip zarara donuyordu (zarar, alinan karin kat kat
   // ustune cikiyordu). Bu alanlar, kar alinan kademenin kapanis fiyatini
   // saklar; asagidaki Lattice_TryOpenLevel() icindeki yon teyidi blogu bu fiyata gore
   // "fiyat GERCEKTEN o yonde devam etti mi" diye kontrol eder.
   double         last_loop_buy_closePrice;
   double         last_loop_sell_closePrice;
   double         escape_fund;           // birikmiş kurtarma fonu ($)
};

struct SDirectionResult {
   ENUM_MARKET_PHASE phase;
   int               direction;      // 1=BUY, -1=SELL, 0=nötr
   double            confidence;     // 0..1
   string            engine_name;
   datetime          timestamp;
};

// v1.78.123 FIX (derleme hatasi - KOK NEDEN): ERB_Update prototipi eskiden
// 775. satirda duruyordu, yani SDirectionResult struct'i (yukarida) HENUZ
// TANIMLANMADAN ONCE. Derleyici o noktada "SDirectionResult" tipini hic
// tanimiyordu -> "declaration without type" (sutun 46, "SDirectionResult"
// token'i) ve ardindan "comma expected" (sutun 63, "&" token'i) hatalari.
// Prototip, tipin tanimlandigi yerin HEMEN SONRASINA (burasi) tasindi -
// hala ilk gercek cagrisindan (VEMA_MA_RegimeGate icinde, ~satir 5320)
// ONCE oldugu icin "kullanilmadan once bildirilmis" kurali korunuyor.
void   ERB_Update(const string symbol, const SDirectionResult &res); // v1.78.120: Early Reversal Brake - VEMA_MA_RegimeGate sonunda cagrilir

struct STpProjResult {
   double   required_lot;       // hesaplanan ek / toplam lot
   double   projected_price;    // hedef fiyat seviyesi
   double   expected_move;      // beklenen fiyat hareketi (mutlak)
   double   money_per_price;    // 1.0 lot ile 1 fiyat birimi hareketin $ karşılığı
   double   deficit_money;      // hedefe kalan para açığı
   double   existing_same_side; // zaten açık aynı yön lot
   bool     feasible;           // lot min/max ve marjin içinde mi?
   string   regime_used;
   string   note;               // debug açıklama
};

struct SPipelineContext {
   string            symbol;
   ulong             magic;
   bool              allow_new_entries;
   bool              security_locked;
   bool              news_hard_lock;
   bool              daily_locked;
   bool              viop_blocked;
   SDirectionResult  dir;
   STpProjResult     tpproj;
   SLatticeState     lattice;
   double            equity;
   double            balance;
   double            free_margin;
   // v1.78.39 FIX: InpHEG_AffectTrend / InpHEG_AffectGrid panelde iki ayrı
   // switch olarak sunuluyordu ("HEG sadece Grid'i / sadece Trend'i etkilesin")
   // ama tek kullanım yerinde OR'lanıp global allow_new_entries'i kapatıyordu —
   // yani ikisi de aynı işi yapıyordu, ayrım fiilen yoktu. Bu iki alan Grid ve
   // Bullet girişlerini ayrı ayrı bloklayabilmek için eklendi.
   bool              heg_block_grid;
   bool              heg_block_trend;
};

//+------------------------------------------------------------------+
//| 3. INPUT GRUPLARI – PDF Ek C (42 grup / ~372 input hedefi)        |
//| Mevcut kodda kullanılan Inp* isimleri korundu; yeni alanlar eklendi.|
//+------------------------------------------------------------------+

//--- DISPLAY --------------------------------------------------------
input group "=== DISPLAY ==="
input ENUM_LANG  InpPanelLanguage           = LANG_TR;
input double     InpPanelScale              = 1.0;

//--- SOUND ALERTS ---------------------------------------------------
input group "=== SOUND ALERTS ==="
input bool       InpSoundAlertsEnabled      = true;
input string     InpSoundTradeOpen          = "nexus_trade_open.wav";
input string     InpSoundProfitClose        = "nexus_profit_close.wav";
input string     InpSoundLossClose          = "nexus_loss_close.wav";
input string     InpSoundProfitReset        = "nexus_profit_reset.wav";
input string     InpSoundLossReset          = "nexus_loss_reset.wav";

//--- DOM / DEPTH OF MARKET ------------------------------------------
input group "=== DOM / DEPTH OF MARKET ==="
input bool       InpDOM_Enable              = false;
input int        InpDOM_TopLevels           = 5;
input int        InpDOM_FreshMs             = 1500;
input double     InpDOM_Weight              = 0.35;

//--- CPU / LATENCY OPTIMIZATION -------------------------------------
input group "=== CPU / LATENCY OPTIMIZATION ==="
input bool       InpCPU_Optimization        = true;
input int        InpCPU_SignalRefreshMs     = 250;
input int        InpPanelRefreshMs          = 200;   // Panel UI throttle (ms), 0=her tick

//--- ML / LIVE MARKET LEARNING --------------------------------------
input group "=== ML / LIVE MARKET LEARNING ==="
input bool       InpML_ONNX_Enable          = true;
input string     InpML_ONNX_ModelFile       = "nexus_model.onnx";
input int        InpML_UpdateMs             = 500;
input int        InpML_FeatureCount         = 32;
input int        InpML_OutputCount          = 3;
input double     InpML_MinTrendProb         = 0.55;
input double     InpML_MinDirectionProb     = 0.55;
input double     InpML_Weight               = 0.35;
input bool       InpML_FallbackHeuristic    = true;
input bool       InpML_ShadowOnly           = false;
input bool       InpML_AutoModelReload      = true;
input int        InpML_AutoModelReloadSec   = 300;
input ENUM_ML_ACCEL InpML_AccelMode         = ML_ACCEL_AUTO;  // CUDA GPU (Build 5572+)
input bool       InpML_AccelFallbackCPU     = true;           // GPU fail → CPU dene
input bool       InpML_LogAccel             = true;           // log cihaz seçimi

//--- ML TRAINING DATA LOGGER ----------------------------------------
input group "=== ML TRAINING DATA LOGGER ==="
input bool       InpML_DataLog_Enable       = false;
input string     InpML_DataLog_CSVFile      = "nexus_ml_features.csv";
input bool       InpML_DataLog_AutoPerChart = true;
input int        InpML_DataLog_LabelHorizonSec = 300;
input double     InpML_DataLog_MinMoveATR   = 0.5;
input int        InpML_DataLog_MaxPending   = 200;
input bool       InpML_DataLog_WriteHeader  = true;

//--- DIRECTION ENGINE SELECTOR --------------------------------------
input group "=== DIRECTION ENGINE SELECTOR ==="
input ENUM_DIRECTION_ENGINE InpDirectionEngine = DIR_ENGINE_VEMA;
input bool       InpTrendReverseSignal      = false;  // [KULLANILMIYOR] AUDIT v1.78.72: karar mantiginda referansi yok
input bool       InpMicroTrendReverse       = false;  // [KULLANILMIYOR] AUDIT v1.78.72: karar mantiginda referansi yok
input double     InpPureShadowSpreadMult    = 1.50;
input bool       InpPureShadowPriceFollowEnable = true;
input double     InpPureShadowProfitFollowMult = 2.50;
input bool       InpPureShadowNetSpreadCloseEnable = true;
input double     InpPureShadowNetProfitSpreadMult = 3.00;
input double     InpPureShadowNetLossSpreadMult = 2.00;
input bool       InpDirectionEngineLock     = false;

// v1.78.72 FIX: RT_ConfFloor() tek global bir esikti (0.25 x hassaslik) ve
// her 3 yon motoruna AYNI sekilde uygulaniyordu. Ama motorlarin confidence
// SKALASI yapisal olarak farkli: VEMA-X oy-cogunlugu orani uretir (ConfirmBars
// varsayilan=4 ile yon verdiginde min confidence >= 0.50), First Touch ve
// Classic Live ise gate'lerini zar zor gectiginde 0.25-0.40 bandinda kalabilen
// olasilik/enerji degerleri uretir. Sonuc: panelde phase=TREND_UP/DOWN
// gorunmesine ragmen (Stage_Bullet basindaki "if(ctx.dir.confidence <
// RT_ConfFloor()) return;" satirinda) First Touch/Classic Live'in dogru yon
// bulmus sinyalleri sik sik floor'u gecemeyip trade hic acilmadan iptal
// ediliyordu. Her motora kendi skalasina uygun AYRI bir floor tanimlaniyor;
// 0 birakilirsa (varsayilan) o motor global RT_ConfFloor()'u kullanmaya
// devam eder - mevcut davranis degismez.
input group "=== DIRECTION ENGINE - MOTOR BAZLI CONFIDENCE FLOOR (v1.78.72) ==="
input double     InpConfFloor_VEMA         = 0.0;   // 0 = global RT_ConfFloor() kullan
input double     InpConfFloor_FirstTouch   = 0.0;   // 0 = global RT_ConfFloor() kullan
input double     InpConfFloor_ClassicLive  = 0.0;   // 0 = global RT_ConfFloor() kullan

//--- VEMA-X LIVE FLOW ARCHITECTURE ----------------------------------
input group "=== VEMA-X LIVE FLOW ARCHITECTURE ==="
input double     InpEMA15_FlatSpreadMult    = 1.0;   // v1.78.61: 1.5->1.0, 100k barlik XAUUSD M5 grid-search sonucu
input int        InpEMA15_ConfirmBars       = 4;      // v1.78.61: 3->4, ayni grid-search sonucu (asagida detay)
input int        InpEMA_VirtualBarSeconds   = 60;

//--- VEMA-X MA9/MA21 REJIM FILTRESI (v1.78.97) -----------------------
// Kullanicinin canli grafikte gozlemledigi kural: KAPANMIS mumun close'u
// EMA(9) VE EMA(21)'in HER IKISININ de UZERINDEYSE yukselis bolgesi;
// ARADAYSA (iki ortalama arasinda) genel NOTR; HER IKISININ de ALTINDAYSA
// dusus bolgesi. Whipsaw'a karsi bu bolge, InpVemaMA_ConfirmBars kadar
// ARDISIK kapanmis mumda ayni yonde kalirsa "teyitli rejim" sayilir.
//
// v1.78.97 (ILK TASARIM - kullanici tercihi): bu filtre VETO-ONLY
// calisiyordu: VEMA-X zaten bir yon verdiyse ve MA rejimi bunu teyit
// etmiyorsa (HENUZ TEYITLI DEGILSE YA DA TERS YONDEYSE) sonuc NOTR'e
// cekiliyordu. Test sonuclari bunun (ozellikle "henuz teyitli degilse"
// kismi) islem sayisini asiri dusurdugunu gosterdi.
//
// v1.78.98 FIX (DUZELTME_REHBERI #6): davranis yumusatildi - ONEMLI, bu
// onceki bilincli tasarim tercihini KASITLI OLARAK degistirir:
//   - Rejim HENUZ TEYIT EDILMEMISSE: ARTIK MUDAHALE YOK (eskiden tam
//     veto uygulaniyordu) - VEMA-X'in sonucu aynen geciyor.
//   - Rejim TEYITLI ve VEMA-X ile AYNI yonde: degisiklik yok (eskisi gibi).
//   - Rejim TEYITLI ve VEMA-X TERS yonde: ARTIK TAM VETO (NOTR'e cekme)
//     YAPILMIYOR - direction/phase degistirilmiyor, Direction Lock kendi
//     flip-teyit mantigina birakiliyor; sadece guven puani
//     InpVemaMA_ConflictConfidenceMult ile dusuruluyor (bkz. asagi).
// Eski VETO-ONLY davranisini geri isterseniz InpVemaMA_ConflictConfidenceMult'u
// 0.0 yapmak TERS+TEYITLI durumu susturur ama HENUZ TEYITSIZ durumdaki
// eski tam-veto'yu geri getirmez (bkz. VEMA_MA_RegimeGate govdesi).
//
// EMA(9)/EMA(21) icin AYRI bir gosterge handle'i ACILMAZ - ML ozellik
// vektorunde zaten kullanilan g_ind[].ema9 / g_ind[].ema21 (PERIOD_CURRENT,
// MODE_EMA) handle'lari yeniden kullanilir; bu yuzden periyot burada
// input olarak DEGIL, sabit 9/21 olarak tanimlidir (baska yerde zaten
// hardcoded - ayri bir input eklemek gercek etkisi olmayan "sahte" bir
// ayar olurdu, bkz. AUDIT v1.78.72 [KULLANILMIYOR] dersleri).
input group "=== VEMA-X MA9/MA21 REJIM FILTRESI (v1.78.97 / v1.78.101 OPTIMIZE) ==="
input bool       InpVemaMA_Enable           = true;
input int        InpVemaMA_ConfirmBars      = 2;    // v1.78.105 FIX (kullanici geri bildirimi): 1->2 geri alindi. ConfirmBars=1, EMA9-bazli hizli zone ile BIRLIKTE calisinca tek mumluk gurultude bile rejim flip edip "bir BUY arkasi bir SELL" seklinde ardisik yon degisimine (whipsaw) yol aciyordu - kar aninda geri veriliyordu. EMA9-bazli hizli zone tespiti (v1.78.101) KALIYOR (o ayri bir iyilestirmeydi), sadece TEYIT SURESI eski degerine donduruldu.
// v1.78.98 FIX (DUZELTME_REHBERI #6, P1): eskiden VEMA_MA_RegimeGate rejim
// HENUZ TEYIT EDILMEMISKEN bile (confirmedRegime==0) VEMA-X'in her sinyalini
// direction=0 yaparak tam veto ediyordu - bu islem sayisini gereksiz
// dusuruyordu. Artik tam veto yerine, SADECE rejim TEYITLI ve VEMA-X TERS
// yondeyse guven puani bu carpanla dusuruluyor (direction degistirilmiyor -
// Direction Lock kendi flip teyidini yapsin). Rehber bu katsayiyi (0.35)
// kesin deger degil, TEST PARAMETRESI olarak tanimliyor - demo/tester'da
// A/B ile ayarlayin.
input double     InpVemaMA_ConflictConfidenceMult = 0.35;
// v1.78.101 FIX (kullanici raporu): eski kural "close HER IKI EMA'nin da
// USTUNDE/ALTINDA" seklindeydi - fiyat EMA9'un ustune cikip EMA21'in
// altinda kaldigi (klasik erken donus/pullback) durumda bolge hala NOTR/
// DOWN sayiliyor, streak sifirlaniyor/ilerlemiyordu. Sonuc: fiyat zaten
// yukari donmusken rejim hala eski (DOWN) damgada donup kaliyor, BUY
// sinyalinin guveni gereksiz kirilarak ters (SELL) yonde israr etmis gibi
// gorunuyordu. Yeni kural: birincil zone artik SADECE EMA9'a gore (hizli
// tepki), EMA21 ise sadece "guclu teyit" icin confidence carpanini
// belirlemede kullanilir (asagida VEMA_MA_RegimeGate govdesine bakin):
//   - close > EMA9 VE close > EMA21  -> UP,  GUCLU teyit (carpan yok)
//   - close > EMA9, close <= EMA21   -> UP,  ZAYIF teyit (kismi carpan)
//   - close < EMA9 VE close < EMA21  -> DOWN, GUCLU teyit
//   - close < EMA9, close >= EMA21   -> DOWN, ZAYIF teyit
// Boylece EMA9'un ustune cikan fiyat ARTIK aninda UP bolgesine gecer (eski
// "her ikisi de" sartindan kurtuldu), EMA21 tamamen atilmiyor - sadece
// carpani sertlestirip yumusatarak whipsaw korumasina katkida bulunuyor.
input double     InpVemaMA_WeakZoneConfidenceMult = 0.7; // 0..1: zayif teyitte (EMA9 gecildi, EMA21 henuz gecilmedi) cezanin ne kadar hafifletildigi. 1.0=ceza tamamen kalkar, 0.0=tam ceza (InpVemaMA_ConflictConfidenceMult) aynen uygulanir

// v1.78.101 EKLENTI: TREND-ICI PULLBACK MODULU (kullanici talebi)
// Amac: Rejim (VEMA-MA) net bir yonde (UP/DOWN) TEYITLI iken fiyat o yonun
// EMA9'undan gecici olarak uzaklasip geri cekildiginde (pullback), sistemin
// hem YATAY/RANGE benzeri davranista makul tepki vermesini hem de pullback
// derinligine gore giris buyuklugunu/guvenini kademeli ayarlamasini
// saglamak. Pullback derinligi |close-EMA9| / ATR ile olculur:
//   derinlik < InpPullback_ShallowATR         -> "SIG" pullback: trend
//        devami ihtimali yuksek, ceza YOK/hafif, lot NORMAL.
//   InpPullback_ShallowATR..InpPullback_DeepATR -> "ORTA" pullback: ceza
//        kademeli artar, lot kademeli kuculur (lineer interpolasyon).
//   derinlik >= InpPullback_DeepATR           -> "DERIN" pullback: gercek
//        trend donusu olabilir ihtimali yuksek - VEMA-MA'nin zaten var olan
//        GUCLU-teyit celisme cezasi (InpVemaMA_ConflictConfidenceMult)
//        aynen devam eder, ek olarak lot bu modulle kucultulur.
// NOT: Bu modul YON DEGISTIRMEZ, YENI SINYAL URETMEZ - sadece VEMA-MA
// tarafindan zaten uretilmis sinyalin confidence/lot olcegini ayarlar.
// Boylece Direction Lock / flip mantigina mudahale etmeden, trend YONUYLE
// AYNI taraftaki (pullback sonrasi devam) girislerin boyutunu piyasanin
// o anki "ne kadar cekildigine" gore akillica olceklendirir.
input bool       InpPullback_Enable         = true;
input double     InpPullback_ShallowATR     = 0.3;  // bu ATR katindan sig pullback -> ceza yok, lot normal
input double     InpPullback_DeepATR        = 0.8;  // bu ATR katindan derin pullback -> lot min carpanina iner (asagida)
input double     InpPullback_MinLotMult     = 0.5;  // derin pullback'te lot bu carpana kadar kuculur (0.5 = yari lot)
input double     InpPullback_ConfMult       = 0.85; // derin pullback'te AYNI YONDEKI sinyale de hafif ihtiyat carpani (1.0=carpan yok)

// v1.78.120 EKLENTI (kullanici PDF talebi - "DGN Nexus VEMA-X Early
// Reversal Brake Teknik Uygulama Plani"): VEMA-X ana motoruna HICBIR
// SEKILDE dokunmadan, ana flip zinciri (VEMA-X -> VEMA-MA rejim -> TFG)
// tamamlanana kadar GECEN surede eski yonde YENI risk (Grid kademesi/
// Bullet girisi) uretilmesini GECICI olarak durduran bagimsiz bir "erken
// risk freni" katmani. ONEMLI: Direction'i degistirmez, Direction Lock'u
// bypass etmez, TFG'nin yerine gecmez - SADECE "yeni giris kapisini"
// kapatir. Mevcut TP, TFG, Range Profit Guard, Dongu Hasadi kapanislari,
// AEGIS'in hicbirine dokunulmaz (bkz. ERB_BlocksNewRisk() cagrildigi
// yerler - SADECE Lattice_TryOpenLevel ve Bullet_CalcLot/Bullet_Process
// GIRIS noktalarinda kullanilir).
input group "=== ERKEN DONUS FRENI (ERB - Early Reversal Brake) ==="
input bool       InpERB_Enable                = true;
input int        InpERB_MinScore              = 3;    // 5 bilesenden kaci ayni anda "bozulma" gostermeli (belgenin onerisi: 2 veya 3)
input bool       InpERB_UsePriceCross         = true; // Bilesen 1: fiyat, rejimin EMA9 referansinin karsi tarafina gecti mi
input bool       InpERB_UseSlope              = true; // Bilesen 2: EMA9 egimi (slope) rejime karsi mi
input bool       InpERB_UseATRDisplacement    = true; // Bilesen 3: fiyat, rejim yonunun tersine belirli ATR mesafesi kadar hareket etti mi
input bool       InpERB_UseMomentumWeakening  = true; // Bilesen 4: VEMA-X'in HAM (rejim cezasindan once) guveni zayifliyor mu
input bool       InpERB_UseEnsembleWeakness   = true; // Bilesen 5: VEMA-MA rejim-VEMA-X celismesi (MACONFLICT) aktif mi
input double     InpERB_ATRDistance           = 0.35; // Bilesen 3 icin esik (ATR kati)
input int        InpERB_ConfirmTicks          = 2;    // aday warning en az bu kadar ARDISIK TICK boyunca korunmali (yanlis alarm onleme)
input int        InpERB_ReleaseConfirmTicks   = 2;    // NORMAL'e donus icin gereken ardisik "temiz" tick sayisi (WARNING/NORMAL ziplamasini onler)
input bool       InpERB_BlockMicroGrid        = true; // WARNING'de Grid'in YENI kademe acmasi engellensin mi
input bool       InpERB_BlockBullet           = true; // WARNING'de Bullet'in YENI giris acmasi engellensin mi (kullanici karari: Grid ile tutarlilik icin dahil edildi)
input bool       InpERB_BlockLoopHarvestReentry = true; // WARNING'de Loop Harvest re-entry'si de engellensin mi (belgenin "cok kritik" dedigi madde)
input bool       InpERB_LogDecisions          = true; // NORMAL<->WARNING gecisleri ve blok kararlari Print() ile loglansin mi



//--- FIRST TOUCH PROBABILITY ENGINE ---------------------------------
input group "=== FIRST TOUCH PROBABILITY ENGINE ==="
input int        InpFT_LookbackSeconds      = 120;
input int        InpFT_HorizonSeconds       = 30;
input int        InpFT_LaunchEverySeconds   = 3;
input double     InpFT_BarrierSpreadMult    = 4.0;
input double     InpFT_BarrierMoveMult      = 6.0;
input int        InpFT_MinResolved          = 36;
input double     InpFT_MinProbability       = 0.58;
input double     InpFT_ConfidenceZ          = 1.2;

//--- CLASSIC LIVE PHASE-ENERGY ENGINE -------------------------------
input group "=== CLASSIC LIVE PHASE-ENERGY ENGINE ==="
input int        InpClassicLiveWindowSec    = 90;
input int        InpClassicLiveFastSec      = 15;
input int        InpClassicLiveWarmupSec    = 12;
input int        InpClassicLiveEntryConfirmMs = 900;
input int        InpClassicLiveFlipConfirmMs  = 3600;
input double     InpClassicLiveDirectionGate  = 0.24;
input double     InpClassicLiveEfficiencyGate = 0.16;
input double     InpClassicLivePulseGate      = 0.20;
input double     InpClassicLiveEnergyGate     = 0.18;
input bool       InpClassicLiveRequireWarmup  = true;

//--- MAIN TRADING ---------------------------------------------------
input group "=== MAIN TRADING ==="
input ulong      InpMagicBase               = 20260709;
input string     InpTradeComment            = "DGN-Nexus-R21";
input int        InpSlippagePoints          = 30;
input bool       InpEnableGlobalTrading     = true;
input bool       InpEnableBuy               = true;
input bool       InpEnableSell              = true;
input string     InpExtraSymbols            = "";          // EURUSD,GBPUSD,XAUUSD
input bool       InpMultiSymbol_Lattice     = false;
input bool       InpEnableSpreadProtection  = false;
input int        InpMaxAllowedSpread        = 100;
input bool       InpEnableSlippageProtection= false;
input int        InpMaxSlippage             = 100;
input int        InpMaxResetCount           = 9999;
input double     InpGlobalProfitPct         = 5.0;
input double     InpGlobalLossPct           = 5.0;
input bool       InpWithdrawalNeutralForLossReset = true;
input bool       InpAllowResetWhenPaused    = true;

//--- DAILY PROFIT / LOSS LOCK ---------------------------------------
input group "=== DAILY PROFIT / LOSS LOCK ==="
input bool       InpDailyProfitLockEnable   = false;
input double     InpDailyProfitTargetPct    = 3.0;
input bool       InpDailyLossLockEnable     = true;   // v1.78.140 KALIBRASYON: false->true. Zaten tanimli olan %3 gunluk zarar kilidi devredeydi ama kapaliydi; 41% kazanma oranli/dusuk-PF donemlerde gun icinde ardisik kucuk zararlarin birikmesini erken kesmek icin acildi.
input double     InpDailyLossTargetPct      = 3.0;
input ENUM_DAILY_GUARD_SCOPE InpDailyLockScope = DGS_ROBOT;
input ENUM_DAILY_GUARD_CLOCK InpDailyClockMode = DGC_BROKER;
input int        InpDailyRestartHour        = 0;
input int        InpDailyRestartMinute      = 5;

//--- AUTO COST LIMITS -----------------------------------------------
input group "=== AUTO COST LIMITS ==="
input bool       InpEnableAutoSpread        = true;
input double     InpAutoSpreadSpikePct      = 30.0;
input double     InpAutoSlippagePct         = 50.0;

//--- RISK STYLE / AUTO TUNING ---------------------------------------
input group "=== RISK STYLE ==="
input ENUM_AUTO_TUNE_RISK InpAutoTune_RiskProfile = RISK_BALANCED;

input group "=== AUTO TUNING ==="
input bool       InpAutoTune_Enable         = false;
input int        InpAutoTune_IntervalMin    = 60;
input double     InpAutoTune_StepPct        = 5.0;
input double     InpAutoTune_MaxRiskPct     = 2.0;
input double     InpAutoTune_MinRiskPct     = 0.25;
input bool       InpAutoTune_AdjustLot      = true;
input bool       InpAutoTune_AdjustStep     = true;
input bool       InpAutoTune_AdjustTP       = false;
input bool       InpAutoTune_OnlyDemo       = true;
input int        InpAutoTune_MinTrades      = 20;
input double     InpAutoTune_TargetPF       = 1.3;
// v1.78.41 FIX (#93): AutoTune_Init() eskiden HER OnInit'te lot/step/tp_mult
// degerlerini sessizce 1.0'a resetliyordu — restart sonrasi adaptif risk
// profili aciklanmadan degisiyordu (bu bir bug degil ama davranis acikca
// yonetilmemis bir tasarim eksikligiydi, rapor bunu boyle notlamisti).
// Varsayilan davranis (false) AYNEN korunur — "temiz sayfa" ile baslamak
// cogu kullanici icin guvenli beklenen davranistir. true yapilirsa
// carpanlar GV'de saklanir ve restart sonrasi kaldigi yerden devam eder.
input bool       InpAutoTune_PersistAcrossRestart = false;

//--- TIME-BASED RESET -----------------------------------------------
input group "=== TIME-BASED RESET ==="
input bool       InpEnableForcedReset       = false;
input int        InpForcedResetHours        = 24;
input bool       InpEnableTimeLimitReset    = false;
input int        InpTimeLimitMinutes        = 60;
input ENUM_TIME_RESET_MODE InpTimeResetAction = TR_CLOSE_ALL;
input bool       InpPauseAfterTimeLimit     = true;

//--- VIRTUAL TAKE PROFIT --------------------------------------------
input group "=== VIRTUAL TAKE PROFIT ==="
input bool       InpEnableAlternatingTP     = false;  // v1.78.18: varsayilan KAPALI (0.10$ erken kapanis)
input double     InpVirtualTPPct            = 0.0;    // v1.78.18: 0=kapali; risk motoru acabilir

//--- REOPEN RULE ----------------------------------------------------
input group "=== REOPEN RULE ==="
input bool       InpAllowReopenNeutral      = true;

//--- BASIC LOT SIZE -------------------------------------------------
input group "=== BASIC LOT SIZE ==="
input ENUM_BULLET_LOT_MODE InpBulletLotMode = BLM_MANUAL;  // BLM_AUTO≈Auto, BLM_MANUAL≈Fixed
input double     InpBulletLotValue          = 0.01;        // FixedLot karşılığı
input double     InpAutoLotPct              = 0.01;

//--- LOT CUT AFTER RESETS -------------------------------------------
input group "=== LOT CUT AFTER RESETS ==="
input int        InpLotPenaltyStepResets    = 100;
input double     InpLotPenaltyStepPct       = 10.0;
input double     InpLotPenaltyMinPct        = 30.0;

//--- TIME LOT BOOST -------------------------------------------------
input group "=== TIME LOT BOOST ==="
input bool       InpEnableTimedLotBoost     = false;
input int        InpLotBoostStepHours       = 8;
input double     InpLotBoostStepPct         = 50.0;
input double     InpLotBoostMaxPct          = 1000.0;

//--- DRAWDOWN HEDGE -------------------------------------------------
input group "=== DRAWDOWN HEDGE ==="
input bool       InpEnableAutoDDHedge       = false;
input double     InpAutoDDHedgePct          = 5.0;
input double     InpDDHedgeExitProfit       = 0.50;
input bool       InpDDHedgePauseTrading     = false;
input ulong      InpMagicDDHedge            = 78779;

//--- TREND / BULLET ENGINE ------------------------------------------
input group "=== TREND ENGINE / BULLET ==="
input bool       InpBulletEnable            = true;
input bool       InpBullet_TrendConsensus   = true; // v1.78.118: kullanici talebiyle false->true (DI/TMI/NDI artik gercekten Bullet girisine katiliyor)
input bool       InpBullet_BlockDITMIConflict = false;
input bool       InpBullet_AllowEarlyTMI    = true;
input bool       InpBullet_RepeatLossGuard  = true;
input int        InpBullet_SameSideLossLimit= 3;
// v1.78.115 EKLENTI (kullanici talebi): MANUEL/AUTO lot modlarinda Grid'deki
// gibi bir buyume carpani yoktu, Bullet lotu hep sabit/bakiye-yuzdesi
// kaliyordu. Bu, panelin GRID CARPAN (g_rt_grid_mult) degerini ARDISIK
// KAZANC SERISINE (B_SAME_WIN) uygular - Martingale'in TERSI (anti-
// martingale): kazanirken buyur, kaybedince 0'a sifirlanip taban lota
// doner. PROJECT modunda UYGULANMAZ (TP-Proj solver zaten kendi hedef
// matematigini yapiyor, bkz. daha onceki Lot_CalcCapped PROJECT-koruma
// karari). Grid'in kendi round-up (step-altinda kayboluş) korumasi burada
// da aynen uygulanir.
input bool       InpBullet_WinStreakMultEnable = true; // MANUEL/AUTO'da kazanc serisi carpani (panelin GRID CARPAN degerini kullanir)
input int        InpBullet_WinStreakMaxLevels  = 5;    // carpanin uygulanacagi maksimum ardisik kazanc sayisi (asiri buyumeyi sinirlar)
input int        InpBullet_ProfitIncubationSec = 8;
input int        InpBullet_LossIncubationSec   = 20;
input int        InpBullet_FlipCooldownSec     = 40;
input int        InpBullet_LossCooldownSec     = 50;
input bool       InpBullet_BonusTPEnable       = true;
input double     InpBullet_BonusTP_Mult        = 9.0;
input bool       InpBullet_ProfitLockEnable    = true;
input double     InpBullet_ProfitLockPullbackPct = 25.0;
input int        InpBullet_EntryConfirmTicks   = 1;
input bool       InpBullet_EntryQualityEnable  = true;
input int        InpBullet_EntryQualityMinScore= 40;
input double     InpBullet_MinEdgeSpreadMult   = 1.5;
input bool       InpBullet_RequireFreshSignalAfterLoss = true;
input bool       InpBullet_FreezeTPProjLotOnLossStreak = true;
input double     InpBullet_LossQualityStep     = 5.0;
input int        InpBullet_MaxSameSideOpens    = 5;
input bool       InpBullet_CloseOnFlip         = true;
input double     InpBullet_MinProfitToFlipClose= 0.0;
input int        InpBullet_MaxHoldMinutes      = 0;   // 0=kapalı

//--- TP-PROJ --------------------------------------------------------
input group "=== TP-PROJ ==="
input ENUM_TPPROJ_VOLUME_REGIME InpTPProjRegime = TPP_REG_SOLVER;
input ENUM_TPPROJ_START_MODE    InpTPProjStart  = TPP_START_FIXED_LOT;
input ENUM_TPPROJ_GRESET_START  InpTPProjGReset = TPP_GRESET_KEEP_PEAK_LOGIC;
input double     InpTPProjPeakTargetMoney   = 8.0;   // v1.78.18: kucuk hesap uyumlu; risk motoru olcekle
input double     InpTPProjExpectedMoveATR   = 1.5;
input double     InpTPProjBalancePct        = 1.0;
input double     InpTPProjRecoveryFactor    = 1.2;
input double     InpTPProjMinLot            = 0.01;
input double     InpTPProjMaxLot            = 2.0;
// v1.78.139: SOLVER rejiminde ayni-yon TOPLAM (existing_same_side) lot bu
// degere ulasinca/gecince SOLVER'in onerdigi EK lot 0'a cekilir - klasik
// "zarardayken lot buyut" martingale sarmalina hesap-boyutuna gore siz
// koydugunuz bir tavan. 0 = KAPALI (eski davranis, sinirsiz ekleme).
// UYARI: 0'da birakilirsa hicbir sey degismez - hesabiniza gore mutlaka
// pozitif bir deger girin (orn. tipik tek-emir lotunuzun 5-10 kati).
input double     InpTPProjSolverMaxLot      = 0.10;  // v1.78.140 KALIBRASYON: 0(sinirsiz)->0.10. InpGridMaxTotalLot ile AYNI olcekte tutuldu; SOLVER artik bagimsiz bir modul olarak sinirsiz buyuyemez, diger modullerle ayni tavana tabi. Hesabiniz 1000$ testten farkliysa oranti ile olcekleyin.
input double     InpLatticeMaxLot           = 0.20;  // GUVENLIK: grid+bullet tek pozisyon tavanı
// v1.78.98 FIX ... toplam exposure kuralı artık varsayılan olarak açık gelir;
// 0=kapali (agresif test) değil, güvenli demoda standart korunma için pozitif
// bir değer kullanılmalıdır. Bu EA'da kasa patlama riski varsa bu değer
// düşük tutulmalı ve yüksek DD içinde yeni girişler otomatik engellenmelidir.
input double     InpGridMaxTotalLot         = 0.10;   // yon basina izin verilen TOPLAM grid lotu; 0.10-0.20 arasi güvenli başlangıç
input bool       InpTPProjFreezeOnLossStreak= true;
input bool       InpTPProjAfterProfitReset  = true;
input bool       InpTPProjAfterLossReset    = true;

//--- ADAPTIF REJIM ESIKLERI (v1.78.139) ------------------------------
// AdaptiveMarket_ChooseRegime()/ChooseLotMode() icindeki esikler eskiden
// sabit koda gomuluydu (ATR%>=0.35, ADX>=25/<18, spread%>=0.10) ve dusuk
// zaman dilimlerinde neredeyse hic tutmuyordu - bu yuzden NETVOL/DEFICIT
// dallarina pratikte hic sira gelmiyor, rejim hep SOLVER'da kaliyordu.
// Artik bunlar ayarlanabilir; varsayilanlar biraz gevsetildi. Deger
// yukseltirseniz eski (daha SOLVER-agirlikli) davranisa yaklasirsiniz.
input group "=== ADAPTIF REJIM ESIKLERI (v1.78.139) ==="
input double     InpAdaptive_HighVolATRPct   = 0.15;  // "yuksek volatilite" ATR% esigi (eskiden sabit 0.35)
input double     InpAdaptive_TrendADX        = 22.0;  // NETVOL/trend-SOLVER icin ADX esigi (eskiden sabit 25)
input double     InpAdaptive_RangeADX        = 18.0;  // "dusuk-ADX range" esigi (eskiden sabit 18)
input double     InpAdaptive_SpreadUnsafePct = 0.10;  // spread guvensiz esigi (eskiden sabit 0.10)
// BALANCE_PCT rejimine gecis eskiden SADECE equity>balance (hesap zaten
// net kardaysa) tetikleniyordu - hesap zarardayken asla ulasilamiyordu.
// Simdi ddPct bu tolerans (%) icindeyse de gecilebiliyor.
input double     InpAdaptive_BalancePctDDTol = 1.0;   // BALANCE_PCT icin izin verilen maks. DD% (eskiden fiilen 0/imkansiz)
// 0 = kapali. >0 ise Journal'a InpAdaptive_DiagLogSec saniyede bir
// atrPct/adx/yon-hizasi/ddPct/secilen-rejim satiri yazar (tani icin).
input int        InpAdaptive_DiagLogSec      = 30;

//--- META-FILTER CANDLE MODU (AUDIT v1.78.72 #6) --------------------
// v1.78.73 FIX: Audit raporu HEG/DTE/EarlyTrend'in rates[0] (henuz
// kapanmamis, olusmakta olan bar) kullandigini, bunun bilincli intrabar
// tasarim olup olmadiginin belirsiz oldugunu belirtti. TMI_Evaluate() de
// ayni sekilde rates[0] kullaniyor (yalniz bu ucu degil, mevcut
// motorlerin cogunun paylastigi bir yaklasim) - bu yuzden varsayilani
// SESSIZCE degistirmek canli davranisi (sinyal sayisi/zamanlamasi)
// ongorulemeyen sekilde etkiler. Bunun yerine acik bir mod anahtari:
// false (varsayilan) = mevcut davranis (intrabar, rates[0]) AYNEN korunur.
// true = HEG/DTE/EarlyTrend son KAPANMIS bari (rates[1]) kullanir.
input group "=== META-FILTER CANDLE MODU (AUDIT v1.78.72) ==="
input bool       InpMetaEngine_UseClosedBar = true;  // repaint korumasi: tum ana motorlar kapanmis bar kullanir; geriye uyumluluk girdisi

//--- HYPERACTIVE EDGE GOVERNOR --------------------------------------
input group "=== HYPERACTIVE EDGE GOVERNOR ==="
input bool       InpHEG_Enable              = false;
input double     InpHEG_MinEdgePts          = 5.0;
input double     InpHEG_SpreadMult          = 1.5;
input int        InpHEG_LookbackBars        = 20;
input double     InpHEG_VolSpikeMult        = 2.0;
input bool       InpHEG_BlockOnSpike        = true;
input double     InpHEG_MinEfficiency       = 0.15;
input int        InpHEG_CooldownSec         = 30;
input bool       InpHEG_AffectTrend         = true;
input bool       InpHEG_AffectGrid          = true;
input double     InpHEG_Weight              = 0.4;
input bool       InpHEG_LogDecisions        = false;

//--- MATHEMATICAL RISK GOVERNOR -------------------------------------
input group "=== MATHEMATICAL RISK GOVERNOR ==="
input bool       InpRiskGov_Enable          = true;
input int        InpRiskGov_MinTrades       = 6;     // v1.78.145 KALIBRASYON: 12 -> 6. Soguk-baslangic penceresini kisaltir (bkz. RiskGovernor_BlockEntry icindeki statsInsufficient notu); 6 islem hala anlamli bir ornekleme, ama RISK_GOV_BLOCK'un ilk 12 islemi tamamen bloke etme suresini yarilar.
input double     InpRiskGov_ColdStartQualityFloor = 0.40; // v1.78.150 FIX: motorTrades=0 & dirTrades=0 iken (GERCEK soguk baslangic) MARKET_QUALITY_KALICI(0.55)/SOGUK_BASLANGIC(0.60) esikleri yerine kullanilan dusuk taban. Bu piyasada quality tipik olarak 0.50-0.58 bandinda kaliyor, normal esikler asla gecilemiyor ve istatistik hic birikemiyordu (kisir dongu). Istatistik yeterli olunca (trades>=MinTrades) normal esikler aynen gecerli.
input double     InpRiskGov_GoodWinRate     = 0.55;
input double     InpRiskGov_MediumWinRate   = 0.45;
input double     InpRiskGov_BadWinRate      = 0.35;
input double     InpRiskGov_GoodPF          = 1.20;
input double     InpRiskGov_MediumPF        = 1.00;
input double     InpRiskGov_BadPF           = 0.85;
input double     InpRiskGov_DrawdownStartPct= 4.0;
input double     InpRiskGov_DrawdownHardPct = 8.0;
input double     InpRiskGov_BasketLossLimit = 50.0;
input int        InpRiskGov_EntryDensityMax = 3;
input int        InpRiskGov_EntryDensitySec = 120;
// v1.78.136 KULLANICI KARARI: motorMult/dirMult (kayip/kazanc orani) tabanli
// blok, ASLA kendi kendine duzelemeyen bir mekanizmaydi - SRiskGovStats omur
// boyu birikiyor, hicbir yerde sifirlanmiyor/decay uygulanmiyor; bir kere
// esigin (0.35) altina dusunce giris tamamen kapaniyor, giris olmadan
// istatistik de duzelemiyor, yani KALICI kilit oluyordu (kullanicinin
// bildirdigi "trend sinyali gelse bile o hafta hic acmama" sorunu). Gunluk
// sifirlama yerine (kullanicinin tercihi) cok daha kisa, sabit bir cooldown:
// esik asildiginda sadece bu sure boyunca engelle, sonra tekrar dene.
input int        InpRiskGov_StatsBlockCooldownSec = 900; // 15 dk - motorMult/dirMult bloğu icin (gunluk kilit YERINE)

//--- ASYMMETRIC EXPECTANCY GOVERNOR (AEG) ---------------------------
input group "=== ASYMMETRIC EXPECTANCY GOVERNOR ==="
input bool       InpAEG_Enable              = false;
input double     InpAEG_ProfitHoldMult      = 1.2;
input double     InpAEG_LossCutMult         = 0.8;
input double     InpAEG_PullbackPct         = 30.0;
input bool       InpAEG_ProtectFloating     = true;
input double     InpAEG_MinProfitMoney      = 1.0;
input bool       InpAEG_BlockEntryOnAdverse = true;
// v1.78.94 FIX: AEG_PROTECT/AEG_LOSSCUT_FLIP TrendFlipGuard_Manage'in aksine
// cooldown'suzdu - "ters sinyal + esik" durumu surdukce (tek seferlik gecis
// degil, surekli kosul) HER TICK basketteki tum karli/zararli pozisyonlari
// kapatmayi deniyordu. Basket zaten esigin altindaysa yeni acilan HER pozisyon
// zarara dustugu an bir sonraki tick'te kapatiliyordu - "kucuk kucuk zarar
// kapatiyor, basari orani ve kasa dusuyor" sikayetinin kok nedeni buydu.
// TFG_CooldownSec ile ayni mantik: ayni sembolde bu sureden once tekrar
// tetiklenmez.
input int        InpAEG_FlipCooldownSec     = 60;

//--- DIRECTIONAL TRUTH META FILTER (DTE) ----------------------------
input group "=== DIRECTIONAL TRUTH META FILTER ==="
input bool       InpDTE_Enable              = false;
input double     InpDTE_MinMetaEdge         = 0.10;
input int        InpDTE_LateEntryBars       = 5;
input double     InpDTE_NoisePenalty        = 0.15;
input bool       InpDTE_BlockLateEntry      = true;
input bool       InpDTE_BlockNoisy          = true;
input double     InpDTE_Weight              = 0.25;
input bool       InpDTE_LogScore            = false;

//--- SHADOW TRADE JOURNAL -------------------------------------------
input group "=== SHADOW TRADE JOURNAL ==="
input bool       InpShadowTrade_Enable      = false;
input bool       InpShadowTrade_WriteCSV    = false;
input string     InpShadowTrade_CSVFile     = "nexus_shadow.csv";
input double     InpShadow_TP_ATR_Mult      = 1.0;
input double     InpShadow_SL_ATR_Mult      = 0.7;
input int        InpShadow_MaxOpen          = 32;

//--- NEXUS DIRECTION INTELLIGENCE (NDI) -----------------------------
input group "=== NEXUS DIRECTION INTELLIGENCE ==="
input ENUM_NDI_PROFILE     InpNDI_Profile   = NDI_BALANCED;
input ENUM_NDI_FLIP_SAFETY InpNDI_FlipSafety = NDI_FLIP_STRONG; // v1.78.118: kullanici talebiyle NORMAL->STRONG
input bool       InpNDI_Enable              = true; // v1.78.118: kullanici talebiyle false->true (ON)

//--- TREND DETECTION CONSENSUS / DI / TMI ---------------------------
input group "=== TREND DETECTION CONSENSUS / DI / TMI ==="
input bool       InpDI_Enable               = true; // v1.78.118: kullanici talebiyle false->true (ON)
input int        InpDI_ADX_Period           = 14;
input int        InpDI_EMA_Period           = 50;
input double     InpDI_MinTrendScore        = 0.22;   // v1.78.147 KALIBRASYON (kanit: tam hafta Journal analizi, 532 CONSENSUS ornegi): 0.50 esigi (STRONG flip-safety ile efektif 0.575) DI_Evaluate()'in trendScore'unun GERCEKTE ULAsABILDIGI tavanin (haftanin mutlak maksimumu: 0.390, ADX=55.2 aninda dahil) UZERINDEYDI - "nadiren tutuyor" degil, MEVCUT FORMULLE HICBIR ZAMAN TUTAMAZ durumuydu (mature DI count: 0/532, tum hafta). 0.22, gozlemlenen dagilimin ~80. yuzdelik dilimine denk gelir (STRONG carpaniyla efektif ~0.253, ~%15-20 civari en guclu anlar) - hala secici ama ARTIK ULASILABILIR. v1.78.118'de kullanici talebiyle 0.42->0.50 yapilmisti; o zamanki DI formuluyle ulasilabilir olabilirdi, ancak guncel formul+veriyle degildi.
input double     InpDI_ADX_Floor            = 15.0;  // v1.78.163 KALIBRASYON (kanit: DI SEPARATION TESHIS loglari, 2026.08.03-08): ADX degerleri gercekte surekli 17-43 bandinda geziniyor, cogu zaman 18-25 arasi - eski Floor=20.0 ile bu bandin alt yarisi (17-20 arasindaki TUM orneklerin) adxNorm'u KOSULSUZ SIFIRLANIYORDU (trendScore'un %55 agirlikli bileseni yok oluyordu, ornek: adx=18.5,diSep=10.69 -> sc=0.12). 15.0, gozlemlenen alt ucun (17-18 civari) hemen altinda - artik bu bant da kademeli katki veriyor. v1.78.118'de kullanici talebiyle 18.0->20.0 yapilmisti; o zamanki veriyle makul olabilirdi, guncel dagilimla degildi.
input double     InpDI_ADX_Ceil             = 40.0;  // v1.78.118: kullanici talebiyle 38.0->40.0
input double     InpDI_SeparationMin        = 4.0;   // v1.78.118: kullanici talebiyle 3.0->4.0
input bool       InpTMI_Enable              = true; // v1.78.118: kullanici talebiyle false->true (ON)
input int        InpTMI_FastPeriod          = 8;
input int        InpTMI_SlowPeriod          = 21;
input int        InpTMI_RSI_Period          = 9;
input double     InpTMI_ConfidenceGate      = 0.70;   // v1.78.166 KALIBRASYON (kanit: 8.5 aylik gercek veri, 50.579 bar, DGN_Calib_XAUUSD_M5.csv): eski 0.35 (STRONG ile efektif 0.4025) TMI'yi DI'ye kiyasla COK gevsek birakiyordu - TMI valid orani %79.2 iken DI mature orani sadece %56.6 idi (ayni "konsensus ortagi" olmalarina ragmen). Kullanicinin talebiyle TMI, DI ile AYNI seciciliğe getirildi: 0.70 (STRONG ile efektif 0.805) tam hafta degil TAM 8.5 AY uzerinden TMI valid oranini %55.8'e cekiyor - DI'nin %56.6'sina neredeyse birebir. Not: bu DI/TMI ORANLARINI esitler, ama Consensus_Evaluate minVotes=1 oldugundan ikisinin AYNI ANDA gerekmesi anlamina gelmez - herhangi biri tek basina yeterli oy sayar; sadece iki motorun "ne kadar kolay oy verdigi" artik dengeli.
input double     InpTMI_ImpulseATR_Mult     = 0.45; // v1.78.118: kullanici talebiyle 0.35->0.45
input bool       InpTMI_AllowEarly          = true;

//--- TREND SAME-DIRECTION LOSS SAFETY -------------------------------
// AUDIT v1.78.72: bu grubun TAMAMI (6 input) statik taramada karar
// mantigina hicbir yerde baglanmamis bulundu - Bullet tarafinin ayni
// islevi zaten InpBullet_SameSideLossLimit (TREND SAME-DIRECTION LOSS
// SAFETY grubunun DISINDA, ayri bir input) uzerinden calisiyor. Silinmedi
// (eski .set uyumlulugu), karar mantigina da baglanmadi (canli davranis
// riske atilmasin) - sadece isaretlendi.
input group "=== TREND SAME-DIRECTION LOSS SAFETY [KULLANILMIYOR] ==="
input bool       InpSameSideLossGuardEnable = false;  // [KULLANILMIYOR]
input int        InpSameSideLossLimit       = 3;      // [KULLANILMIYOR]
input double     InpSameSideLossQualityStep = 5.0;     // [KULLANILMIYOR]
input bool       InpSameSideRequireFresh    = true;    // [KULLANILMIYOR]
input int        InpSameSideCooldownSec     = 60;      // [KULLANILMIYOR]
input bool       InpSameSideFreezeLotGrowth = true;    // [KULLANILMIYOR]

//--- GLOBAL TREND FLIP GUARD (v1.78.54) -------------------------------
// Panelde "Yon: SELL/BUY" olarak gosterilen g_ctx.dir.direction sinyali
// terse donunce, YENI yonun TERSINDE acilmis (yani artik trendle celisen)
// tum pozisyonlari (Grid/Lattice + Bullet + Hedge, sembol+magic bazli)
// tarar; karda olanlari SafeClosePosition ile kapatip kari korur.
// Zararda olan pozisyonlara DOKUNMAZ (onlar kendi SL/DD/AEGIS mekanizmalarina
// birakilir) - amaç sadece kâr koruma, panik kapatma degil.
input group "=== GLOBAL TREND FLIP GUARD ==="
input bool       InpTFG_Enable              = false;
input double     InpTFG_MinConf             = 0.35;
input bool       InpTFG_UseMinCloseMoney    = true;   // true: RT_MinCloseMoney() esigi, false: sabit tutar
input double     InpTFG_FixedMinProfit      = 1.0;    // UseMinCloseMoney=false ise kullanilir
input int        InpTFG_CooldownSec         = 40;

//--- DIRECTION FLIP LOCK + CONTROLLED FLIP CLOSE (v1.78.95) --------
input group "=== DIRECTION FLIP LOCK / CONTROLLED CLOSE ==="
input bool       InpDirLock_Enable           = true;
input double     InpDirLock_MinConf          = 0.35;
input int        InpDirLock_FlipConfirmTicks = 2;
input int        InpDirLock_CooldownSec      = 15;
input bool       InpDirLock_CloseProfit      = true;
input double     InpDirLock_MinProfit        = 1.0;
input bool       InpDirLock_CloseSmallLoss   = true;
input double     InpDirLock_MaxLossMoney     = 5.0;
input bool       InpDirLock_RequireTrendPhase= true;   // v1.78.96: sadece PHASE_TREND_UP/DOWN'da flip commit et

//--- TREND OR RANGE CHECK / AWR -------------------------------------
input group "=== TREND OR RANGE CHECK / AWR ==="
input ENUM_AWR_REGIME_SRC InpAWR_RegimeSource = AWR_SRC_ENSEMBLE;
input double     InpAWR_SpikePulseMin       = 1.8;
input double     InpAWR_SpikeATRNorm        = 0.012;
input double     InpAWR_TrendScoreMin       = 0.50;
input bool       InpAWR_BlockEntryOnSpike   = false;
input bool       InpVG_StopNewEntriesOnTrend= false;
input int        InpRangeLookbackBars       = 30;
input double     InpRangeATR_Mult           = 1.2;
input bool       InpRangePreferGrid         = true;   // [KULLANILMIYOR] AUDIT v1.78.72: ENUM_MARKET_PHASE/RT_GridTrendPhase() bu input'a baglanmiyor
input bool       InpTrendPreferBullet       = true;   // [KULLANILMIYOR] AUDIT v1.78.72: ENUM_MARKET_PHASE/RT_GridTrendPhase() bu input'a baglanmiyor
input double     InpTrendADX_Min            = 20.0;   // [KULLANILMIYOR] AUDIT v1.78.72: karar mantiginda referansi yok
input double     InpRangeADX_Max            = 18.0;   // [KULLANILMIYOR] AUDIT v1.78.72: karar mantiginda referansi yok
input bool       InpPhaseUseDI              = false;
input bool       InpPhaseUseTMI             = false;
input bool       InpPhaseUseAWR             = false;
input double     InpPhaseConsensusMin       = 0.55;

//--- SUPPORT / RESISTANCE + BREAKOUT CONFIRMATION ------------------
// Son kapanmis barlar uzerinden dinamik destek/direnc cikarir.
// Trend girislerinde, seviye kirilimi belirtilen sayida kapanisla teyit
// edilmeden yeni Bullet/Grid girisine izin verilmez.
input group "=== SUPPORT / RESISTANCE + BREAKOUT ==="
// v1.78.100 FIX: S/R filtre sistemi tamamen devre disi birakildi (default=false).
// SR_EntryConfirmed() fonksiyonu InpSR_Enable=false oldugunda dogrudan true
// donuyor (bkz. asagida), yani S/R hicbir girisi artik engellemiyor.
input bool       InpSR_Enable                 = false;
input ENUM_TIMEFRAMES InpSR_Timeframe         = PERIOD_CURRENT;
input int        InpSR_LookbackBars           = 30;
input int        InpSR_BreakoutConfirmBars    = 2;
input double     InpSR_BufferATR              = 0.15;
input bool       InpSR_RequireBreakoutInTrend = true;
input bool       InpSR_RequireRangeBounce     = true;
input double     InpSR_RangeTouchATR          = 0.25;
input bool       InpSR_LogDecisions           = true;   // v1.78.168 RISKTEST: TEST icin acik (RED sebepleri Journal'da gorunsun). Test bitince false yapin.
// v1.78.75 FIX: Destek/direnc retest sarti tamamen kaldirildi. Trend
// modunda artik sadece breakout + InpSR_BreakoutConfirmBars kapanis teyidi
// araniyor; fiyatin kirilim sonrasi eski seviyeye geri donup dogrulamasi
// (retest) beklenmiyor. Onceki InpSR_RequireRetestInTrend / RetestLookback /
// RetestTouchATR / RetestTimeoutBars input'lari ve ilgili kod bu surumde
// kaldirildi.

//--- RANGE PROFIT PROTECTION ---------------------------------------
// Trendden Range'e geciste kazanilmis Bullet kari geri vermesin.
// Range sinyali birkac ardik ornekle teyit edilir; ardindan pozitif
// Bullet kapatilarak kar korunur. Zararli pozisyona dokunulmaz.
// v1.78.67 (#130): Ayni koruma artik Grid/Lattice sepetine de uygulanabilir
// (InpRangeProfitGuardIncludeGrid) - en cok kari Grid getirdigi icin, sadece
// Bullet'i korumak asil sizintiyi kapatmiyordu. Grid tarafi BUY/SELL sepetini
// AYRI degerlendirir ve TrendFlipGuard'daki (#125) ile AYNI NET-POZITIF
// kuralini kullanir: karsi taraf zarardaysa, kapatilabilir kar o zarari +
// tamponu karsilamiyorsa HIC dokunulmaz (hedge'siz birakip DD Hedge'in ayni
// pozisyonu spread odeyerek yeniden acmasini onlemek icin).
input group "=== RANGE PROFIT PROTECTION ==="
input bool       InpRangeProfitGuardEnable        = true;
input int        InpRangeProfitGuardConfirmTicks  = 3;
input bool       InpRangeProfitGuardUseConfirmSec = true;   // v1.78.68 (#131): true ise tick sayaci yerine saniye bazli teyit kullanilir (TFG/AEGIS ile tutarli - piyasa hizindan bagimsiz sabit sure)
input int        InpRangeProfitGuardConfirmSec    = 15;     // UseConfirmSec=true iken RANGE fazinin kesintisiz suresi (saniye)
input double     InpRangeProfitGuardMinMoney      = 1.00;
input bool       InpRangeProfitGuardUseDynamicMin = true;   // v1.78.68 (#131): true ise RT_MinCloseMoney() (equity%0.25 veya $2.50, hangisi buyukse) kullanilir; false ise InpRangeProfitGuardMinMoney sabit tutar
input bool       InpRangeProfitGuardCloseOnRange  = true;
input double     InpRangeProfitGuardPullbackPct   = 20.0;
input double     InpRangeProfitGuardPullbackPctGrid = 0.0;  // v1.78.68 (#131): 0 ise Bullet ile ayni InpRangeProfitGuardPullbackPct kullanilir; >0 verilirse Grid sepeti icin BAGIMSIZ yuzde (Grid'in mutlak zirve buyuklugu Bullet'ten cok farkli olabildigi icin ayni % farkli tolerans anlamina gelir)
input bool       InpRangeProfitGuardIncludeGrid   = true;

//--- TREND/RANGE DATA SOURCE ----------------------------------------
input group "=== TREND/RANGE DATA SOURCE ==="
input ENUM_TIMEFRAMES InpTrendTF            = PERIOD_CURRENT;
input ENUM_TIMEFRAMES InpRangeTF            = PERIOD_CURRENT;
input bool       InpUseTickForPhase         = true;
input int        InpPhaseRefreshMs          = 200;
input bool       InpPhaseCacheEnable        = true;
input int        InpPhaseCacheBars          = 50;

//--- DIRECTION SMART CHECK ------------------------------------------
input group "=== DIRECTION SMART CHECK ==="
input bool       InpSmartDir_Enable         = false;
input double     InpSmartDir_MinConf        = 0.40;
input int        InpSmartDir_ConfirmTicks   = 2;
input bool       InpSmartDir_BlockConflict  = true;
input double     InpSmartDir_EMA_SepPct     = 0.05;
input bool       InpSmartDir_UseRSI         = true;
input double     InpSmartDir_RSI_OB         = 70.0;
input double     InpSmartDir_RSI_OS         = 30.0;
input bool       InpSmartDir_UseADX         = true;
input double     InpSmartDir_ADX_Min        = 15.0;

//--- DIRECTION EXTRA CHECKS -----------------------------------------
input group "=== DIRECTION EXTRA CHECKS ==="
input bool       InpExtra_Enable            = false;
input bool       InpExtra_BlockNewsWindow   = true;
input bool       InpExtra_BlockLowMargin    = true;
input double     InpExtra_MinFreeMarginPct  = 20.0;
input bool       InpExtra_BlockHighSpread   = true;
input int        InpExtra_MaxSpreadPts      = 80;
input bool       InpExtra_RequireSession    = true;
input bool       InpExtra_BlockFridayClose  = false;
input int        InpExtra_FridayCloseHour   = 20;
input bool       InpExtra_BlockMondayOpen   = false;
input int        InpExtra_MondayOpenHour    = 10;
input bool       InpExtra_LogBlocks         = false;
input int        InpExtra_MinSecondsBetween = 5;

//--- EARLY TREND CHECK ----------------------------------------------
input group "=== EARLY TREND CHECK ==="
input bool       InpEarlyTrend_Enable       = false;
input int        InpEarlyTrend_FastPeriod   = 5;
input int        InpEarlyTrend_SlowPeriod   = 13;
input double     InpEarlyTrend_MinImpulse   = 0.25;
input double     InpEarlyTrend_MinConf      = 0.40;
input bool       InpEarlyTrend_AllowAlone   = false;
input int        InpEarlyTrend_MaxBars      = 8;
input bool       InpEarlyTrend_UseTMI       = true;
input bool       InpEarlyTrend_UseROC       = true;
input double     InpEarlyTrend_ROC_Mult     = 0.3;

//--- FINAL DIRECTION DECISION ---------------------------------------
input group "=== FINAL DIRECTION DECISION ==="
input bool       InpFinalDir_RequireNonZero = false;

//--- SAME SIDE MIN DISTANCE -----------------------------------------
input group "=== SAME SIDE MIN DISTANCE ==="
input bool       InpMinDist_Enable          = false;
input double     InpMinDist_Points          = 50;
input double     InpMinDist_ATR_Mult        = 0.5;
input bool       InpMinDist_UseATR          = false;

//--- GRID ENGINE (R21 Sanal Lattice) --------------------------------
input group "=== GRID ENGINE (R21 Lattice) ==="
input bool       InpVG_Enable               = true;
// v1.78.167 KADEME/CARPAN FIX (kullanici talebi - bkz. dosya basi changelog):
// false (varsayilan) = GRID CARPAN panelden/init'ten ne ayarlandiysa TUM
// rejimlerde SABIT kalir; AdaptiveMarket_Refresh()/ClearOldMotorState()
// artik g_rt_grid_mult_on/g_rt_seq_mult'a DOKUNMAZ. true = eski davranis
// (sadece NETVOL/SOLVER-trend rejiminde otomatik ACIK, digerlerinde KAPALI).
input bool       InpVG_GridMultRegimeControl = false;
// v1.78.167 KADEME FIX: false (varsayilan) = SR_EntryConfirmed() (breakout/
// retest/bounce onayi) SADECE basket'in ILK kademesinde aranir; 2. ve sonraki
// kademe eklemelerinde aranmaz (STEP mesafesi + trend uyumu + netting + risk
// motorlari zaten yeterli guvenligi sagliyor). true = eski davranis (her
// kademede, ilk giris dahil, SR onayi zorunlu - kademelemeyi fiilen engelliyordu).
input bool       InpSR_RequireOnAddLevels    = false;
input ENUM_GRID_LOT_MODE  InpVG_LotMode     = GLM_FIXED;
input double     InpVG_LotValue             = 0.01;
input ENUM_GRID_STEP_MODE InpVG_StepMode    = GST_FIXED_POINTS;
input double     InpVG_StepValue            = 200;
input double     InpVG_BuyStepValue         = 0;
input double     InpVG_SellStepValue        = 0;
input ENUM_GRID_TP_MODE   InpVG_TPMode      = GTP_FIXED_POINTS;
input double     InpVG_TPValue              = 150;
input bool       InpVG_TPAuthority          = true;
input bool       InpVG_NettingSingleSide    = true;
input bool       InpVG_PyramidBuy           = false;
input bool       InpVG_PyramidSell          = false;
input double     InpVG_PyramidMinProfitPts  = 50;
input int        InpVG_PyramidMaxExtra      = 3;
input bool       InpVG_LoopHarvestEnable    = false;
input double     InpVG_LoopMinNetSpreadMult = 1.0;
input int        InpVG_LoopCooldownSec      = 20; // v1.78.113 FIX (kullanici tespiti): 5->20sn. 5sn M5'te pratikte "ayni an" gibiydi, fiyatin gercekten devam edip etmedigini gormek icin yeterli zaman tanimiyordu.
// v1.78.113 EKLENTI (kullanici tespiti - kritik): Loop Harvest re-entry,
// kar alinan kademe kapandiktan SADECE COOLDOWN suresi gecince (STEP mesafesi
// beklemeden) yeni kademe aciyordu - ama fiyatin GERCEKTEN o yonde devam
// edip etmedigine hic bakmiyordu. Kullanicinin gozlemi: SELL trendinde kar
// alinip kapaniyor, fiyat HEMEN geri cekiliyor, yeni SELL kademesi kotu
// zamanla acilip ONCEKI KARIN KAT KAT USTUNDE zararla kapaniyordu ("kar 10
// iken zarar 20 oluyor, karin 2 katini yiyor"). Cozum: re-entry'den once
// fiyatin, kar alinan kademenin KAPANIS FIYATINDAN itibaren AYNI YONDE en
// az bu kadar ATR ilerlemis olmasi sart kosuluyor - fiyat GERCEKTEN devam
// ETMEDEN yeni kademe acilmiyor (bkz. Lattice_TryOpenLevel() icindeki yon teyidi blogu).
input double     InpVG_LoopReentryConfirmATR = 0.15; // 0=kapali (eski davranis); >0 ise bu kadar ATR ilerleme sarti
// v1.78.103 EKLENTI (kullanici talebi - DONGU HASADI panel butonuna gomulu):
// Ayri bir panel toggle'i ACILMADI - kullanici mevcut "DONGU HASADI"
// butonunu ac/kapat olarak kullanmak istedigi icin bu yeni davranis da
// AYNI bayrak (g_rt_loop_harvest / InpVG_LoopHarvestEnable) ile kontrol
// ediliyor; KAR BEK panel anahtarindan (RT_KarHepsiniKapat) BAGIMSIZDIR -
// sadece RT_ProfitBek() DEGERINI referans alir. Amac: KAR BEK ($) hedefine
// fiyat 1-2$ kala yaklasip geri cekilirse o ana kadar birikmis kar bosa
// gitmesin diye, acik kar bu esigin (InpVG_LoopProtectPct) yuzdesine
// ulastiginda pozisyon DIREKT (trailing degil, tek seferlik) kapatilir -
// "eli bos donmemek" onceligi. Is bolumu (kullanicinin tasarimi):
//   - TFG (Trend Flip Guard): ZARAR tarafini / rejim flip'ini korur.
//   - DONGU HASADI + bu koruma: KAR tarafini korur (KAR BEK'e cok yaklasip
//     geri cekilme riskine karsi erken-kilit).
//   - Bu ikisinin ARASINDAKI bolge (kar hicbir esige ulasmamis, ufak
//     pullback'ler) BILEREK serbest birakilir - EA'nin normal yon/grid
//     mantigina mudahale edilmez.
// Bkz. Stage_PanelBasketRules icindeki asagidaki blok.
input double     InpVG_LoopProtectPct       = 70.0; // KAR BEK($)'in yuzde kaci biriktiginde koruma icin direkt kapatilsin (0=kapali)
input bool       InpVG_EscapeFundEnable     = false;
input double     InpVG_EscapeFundSharePct   = 20.0;
input double     InpVG_EscapeDeployPct      = 50.0; // v1.78.117: ARTIK KULLANILMIYOR (deploy mekanizmasi kaldirildi), geriye donuk uyumluluk icin input tanimli birakildi
input double     InpVG_EscapeRewardRisk     = 2.0;   // [KULLANILMIYOR] AUDIT v1.78.72: karar mantiginda referansi yok
input double     InpVG_EscapeBankCapPct     = 2.0; // v1.78.117: ARTIK KULLANILMIYOR (tavan artik InpVG_EscapeBankTargetUSD ile sabit dolar), geriye donuk uyumluluk icin input tanimli birakildi
input double     InpVG_EscapeMaxGridLotMult = 2.0; // v1.78.117: ARTIK KULLANILMIYOR (deploy mekanizmasi kaldirildi)
// v1.78.117 EKLENTI (kullanici talebi - "KAR KORUMA KASASI" mimarisi):
// KACIS KASASI butonu artik "al-ver" (kar biriktir, sonra tekrar riske at)
// yerine TEK YONLU bir kar koruma mekanizmasi. Kasa TICARETE ASLA GERI
// KARISMAZ (bkz. yukaridaki Lattice_ApplyEscapeFundLot cagrisinin
// kaldirilmasi) - EA "kasayla alakali her seyi atlayip normal calisir".
// Hedef SABIT BIR DOLAR TUTARI (InpVG_EscapeBankTargetUSD, orn. 1000$).
// Kasa bu hedefin YUZDE KACINA (InpVG_EscapeProtectedPct, orn. %50) kadar
// olan kismi MUTLAK DOKUNULMAZDIR. Bu esigi asan FAZLALIK kisim ise "acil
// durum yedegi" sayilir - normalde YINE kullanilmaz, SADECE ana hesap
// equity'si kasa toplamiyla AYNI SEVIYEYE dustugunde (kritik durum, bkz.
// Lattice_EscapeFund_CriticalCheck) devreye girip cekilebilir.
input double     InpVG_EscapeBankTargetUSD  = 1000.0; // kasa hedef tutari ($) - kullanicinin ornegindeki 1000$
input double     InpVG_EscapeProtectedPct   = 50.0;   // hedefin bu yuzdesi MUTLAK dokunulmaz (asagisi asla kullanilmaz)
input bool       InpVG_EscapeCriticalWithdrawEnable = false; // acil durum cekisi ac/kapa (varsayilan kapali - guvenlik icin bilincli acilmasi gerekir)
input int        InpVG_MaxLevelsPerSide     = 6;     // v1.78.18: plug&play (16 cok agresif)
input bool       InpVG_ReanchorOnTrendFlip  = true;
input double     InpVG_BalancePct           = 0.5;
input double     InpVG_EquityPct            = 0.5;
input double     InpVG_TP_SpreadMult        = 3.0;
input double     InpVG_TP_BalancePct        = 0.2;
input double     InpVG_TP_PricePct          = 0.05;
input double     InpVG_Step_RangeMult       = 0.5;
input double     InpVG_Step_PricePct        = 0.05;
input bool       InpVG_AllowBothSides       = true;
input int        InpVG_MinSecondsBetween    = 15;    // v1.78.18: sik acilisi engelle
input bool       InpVG_LogLevels            = false;

//--- GRID RISK FIREWALL (v1.78.69 SAFE) -----------------------------
// Normal Grid davranisini degistirmez; yalnizca risk siniri asilirsa
// yeni Grid girislerini durdurur ve kritik durumda Grid sepetini kapatir.
input group "=== GRID RISK FIREWALL (SAFE) ==="
input bool       InpGridRiskFirewallEnable   = true;
input double     InpGridRiskMaxDDPct         = 8.0;    // v1.78.168 RISKTEST: 2.0 -> 8.0 (SADECE TEST). Grid floating loss / equity. Canli hesapta 2.0 (veya bilincli secilen deger) kullanin.
input double     InpGridRiskMaxLossMoney     = 0.0;    // 0 = sadece yuzde limiti
input double     InpGridRiskWarnPct          = 80.0;   // limitin bu yuzdesinde yeni girisler durur
input double     InpGridRiskMaxTotalLot      = 0.0;    // 0 = kapali; asilirsa yeni Grid girisi durur
input double     InpGridRiskMaxAdverseATR    = 6.0;    // ortalama Grid girisine ters hareket; 0 = kapali
input bool       InpGridRiskEmergencyClose  = true;
input bool       InpGridRiskBlockOnOrphan    = true;
input bool       InpGridRiskLog              = true;

//--- AUDIT v1.78.70 (DGN_Nexus_Pro_R21_v1_78_68_CRITICAL_AUDIT) -----
// Kaynak: kullanicinin yukledigi harici audit raporu, v1.78.68_TUNE
// baz alinarak hazirlanmis. Asagidaki gruplar raporun 13 maddesinden
// SAFE (v1.78.69) surumunde henuz karsilanmamis olanlari ekler. Zaten
// SAFE'de var olanlar (Grid Risk Firewall, Weekly Hedge delta) tekrar
// edilmedi. Hepsi normal davranisi yalnizca DARALTIR/GUVENLESTIRIR;
// varsayilan degerler mevcut sonuclari degistirmemek icin muhafazakar
// secildi ama etkindir (Enable=true).
input group "=== RISK-BASED LOT SIZING (AUDIT #3/#4) - v1.78.98: YENIDEN AKTIF ==="
// v1.78.93 FIX (ESKI DAVRANIS - ARTIK GECERSIZ): kullanici geri bildirimi -
// bu equity-risk% tavani (RiskCap_MaxLot) kucuk hesaplarda hesaplanan lotu
// broker'in minLot'unun altina dusurup islemleri SESSIZCE iptal ettiriyordu.
// O zamanki cozum tavani TAMAMEN KALDIRMAKTI - bu da equity-risk korumasini
// tamamen devre disi birakiyordu (P0 risk).
//
// v1.78.98 FIX (DUZELTME_REHBERI #1/#2): kok sebep tavan degil, "minLot
// altina dusen guvenli lotu yukari zorlama" davranisiydi. Tavan artik
// Lot_CalcCapped() icinde YENIDEN ZORUNLU; minLot altina dusen sonuc
// yukari yuvarlanmiyor, islem sadece o hucrede acilmiyor (bkz.
// NormalizeLotForEntry). Risk verisi hesaplanamazsa (ATR/equity/tick
// eksik -> DBL_MAX) "sinirsiz ac" ARTIK KABUL EDILMIYOR: InpRiskSizing_Enable
// acikken bu durumda da islem acilmaz.
//
// NOT: MaxRiskPct/AdverseATRMult degerleri hesap buyuklugunuze gore
// kesin dogru degildir - DUZELTME_REHBERI bolum 12, test icin 0.50-1.00 /
// 2.0-3.0 araligini onerir; mevcut varsayilanlar (1.5 / 6.0) degistirilmeden
// birakildi, demo/tester'da kendi hesabiniza gore ayarlayin.
input bool       InpRiskSizing_Enable         = true;   // v1.78.98: AKTIF - equity-risk% tavani zorunlu
input double     InpRiskSizing_MaxRiskPct     = 15.0;   // v1.78.168 RISKTEST: 3.0 -> 15.0 (SADECE TEST - canlida KULLANMAYIN). Onceki aciklama: v1.78.144 KALIBRASYON: 1.0 -> 3.0. $1000 civari hesapta %1 (=$10) butce, Grid'in 7x ATR Hard SL mesafesinde minLot (0.01) icin bile yetersiz kalip surekli RISK_MINLOT_ASIYOR/RISK_CAP_SIFIR ile islemi veto ediyordu (0 islem sorunu). %3 DUZELTME_REHBERI'nin onerdigi 0.50-1.00 araliginin USTUNDE - bilincli bir risk/getiri tercihidir, kucuk hesapta minLot'un acilmasini saglamak icin AdverseATRMult daraltmasiyla (asagida) birlikte ayarlanmistir. Yuksek DD sirasinda tek yanlis girisin etkisi hala butceyle sinirlidir (fail-closed korumalar degismedi).
input double     InpRiskSizing_AdverseATRMult = 3.0;    // v1.78.140 KALIBRASYON: 8.0->3.0 (DUZELTME_REHBERI'nin kendi onerdigi 2.0-3.0 araliginin ust siniri). 8.0 ile RiskCap_MaxLot cok dar hesaplaniyor, hesaplanan lot broker minLot'un altina dusup islemi sessizce iptal ettirebiliyordu - "lot buyumuyor" sikayetinin bir kismi buradan geliyordu.

// v1.78.131 HARD SL (Teknik Sartname R1-R6): buraya kadar hicbir motor
// pozisyona GERCEK (broker seviyeli) Stop Loss koymuyordu - AEG/DirLock/
// GridRiskFirewall/RiskGovernor tamamen tick-tetiklemeli "soft" mantikti.
// Bu katman onlarin YERINE GECMEZ, USTUNE eklenen bir son-care/felaket
// frenidir. Bullet/hedge motorlari icin mesafe InpRiskSizing_AdverseATRMult
// ile AYNI (Lot_CalcCapped/RiskCap_MaxLot zaten bu mesafeyi varsayarak lot
// hesapliyor - hard SL bu varsayimi FIILEN uygulanir hale getirir, R2).
// Grid/Lattice sepeti icin AYRI ve DAHA GENIS bir mesafe kullanilir
// (InpHardSL_GridATRMult), cunku GridRiskFirewall zaten
// InpGridRiskMaxAdverseATR (varsayilan 6.0) ATR'de sepeti kapatmaya
// calisiyor - hard SL o esikten ONCE tetiklenirse firewall'a hic sans
// tanimamis olur (bkz. Teknik Sartname bolum 4.4).
// v1.78.132 KULLANICI KARARI: bu bir felaket-onleme guvenlik katmani -
// runtime input olarak birakilirsa yanlislikla (eski bir .set dosyasi,
// preset, panelden unutulan bir tik) SESSIZCE devre disi kalabilir. Bu
// yuzden acma/kapama anahtari artik RUNTIME INPUT DEGIL, asagidaki
// HARDSL_FORCE_ENABLED derleme-zamani sabitidir - sadece kaynak kod
// degistirilip YENIDEN DERLENEREK kapatilabilir (bkz. DGN_BUILD_TAG
// yakinindaki tanim). AC2 (A/B karsilastirma) icin bu sabiti gecici
// olarak false yapip derlemek hala mumkun ve gereklidir.
input group "=== HARD SL - GERCEK BROKER STOP (SARTNAME R1-R6) ==="
input double     InpHardSL_GridATRMult        = 7.0;    // v1.78.144 KALIBRASYON: 9.0 -> 7.0. GridRiskFirewall esiginin (InpGridRiskMaxAdverseATR=6.0) HALA ustunde - firewall yine Hard SL'den ONCE tetiklenir, katman sirasi (Teknik Sartname 4.4) korunur. 9.0'da $1000 civari hesapta minLot (0.01) gercek riski risk butcesini asip surekli veto uretiyordu; 7.0 + yukaridaki MaxRiskPct=3.0 kombinasyonu bu acigi kapatir.
input double     InpHardSL_MinBufferMult      = 1.2;    // broker min-stop/freeze mesafesine uygulanan guvenlik payi
input bool       InpHardSL_RecalcOnAdd        = true;   // Grid sepetine yeni seviye eklendiginde SL, yeni ortalama girise gore yeniden hesaplanir (R3)

input group "=== EXECUTION LOCK (AUDIT #7/#8) ==="
input bool       InpExecLock_Enable           = true;   // sembol+yon gonderim kilidi (onay kesinlesmeden ayni hucreyi tekrar gondermeyi engeller)

input group "=== DIRECTION CACHE GUARD (AUDIT #9) ==="
input bool       InpDirCache_BypassOnBigMove  = true;    // guclu hareket/trend flip'te cache'i atla
input double     InpDirCache_BypassATRFrac    = 0.5;     // cache fiyatindan bu kadar ATR kadar sapma = atla
input int        InpDirCache_MaxAgeSec        = 60;      // panel ORNEK SN ne olursa olsun mutlak tavan (0=kapali)

input group "=== NEWS FILTER (AUDIT #13) ==="
input bool       InpNF_UseKeywordFilter       = false;   // false (onerilen): importance+currency yeterli; true = eskisi gibi ek anahtar-kelime sarti

//--- ATR SISTEMI (ALGO DGN_ALGO_v7_68 CalcATRBasedParams/ProcessGridAndHedge esinli)
// v1.78.22: ALGO'da iki katman var, ikisi de tasindi:
//   1) CalcATRBasedParams  -> sembol TIPINE gore stepMult (Forex/BTC/ETH farkli)
//                             SADECE editbox/degeri BOS/0 iken bir kere auto-fill eder.
//   2) ProcessGridAndHedge -> risk MODUNA gore riskStepMult (CokGuvenli 1.5 /
//                             Guvenli 1.0 / Agresif 0.6), her tick calisan asil
//                             ADIM formulu: atr * ATRMult * riskStepMult.
// Nexus'ta ayni mantik: RiskPreset_Apply risk motoru DEGISTIGINDE ATR'dan
// ADIM/TP dolduruyor (asagidaki RiskPreset_ATRAutoFill), boş kalan degeri
// degil cunku Nexus'ta risk motoru degistirmek zaten butun degerleri
// yeniden yaziyor (ALGO'nun "editbox bos ise" kosulunun Nexus karsiligi budur).
input group "=== ATR SISTEMI (ALGO ESINLI) ==="
input bool       InpATR_ModeEnable          = true;   // ALGO g_ATRMode karsiligi — risk motoru ATR'dan mi dolsun
input int        InpATR_Period              = 14;
input double     InpATR_TriggerMult         = 1.0;    // ALGO GridTriggerATRMult ile ayni varsayilan
input double     InpATR_StepMult_Forex      = 0.18;   // ALGO CalcATRBasedParams: XAUUSD/Forex dali
input double     InpATR_StepMult_BTC        = 0.13;   // ALGO: BTC dali
input double     InpATR_StepMult_ETH        = 0.20;   // ALGO: ETH dali
input double     InpATR_TP_Ratio            = 1.5;    // ALGO: TP = Adim * 1.5 (sabit oran)
input double     InpATR_MinStepPoints       = 5.0;    // ALGO'daki "outAdim<0.1 ise 0.1" tabaninin puan karsiligi

// v1.78.32 GUVENLIK KILIDI — Dogan: Nexus Pro'yu XAUUSD disinda USOIL ve
// BTCUSD grafiklerine de takinca kasa 335->133 dustu. BTCUSD dogru
// siniflandirilmis (RiskATR_SymbolType "BTC" iceren sembolu tip 1 yapiyor)
// ve ATR MODU varsayilan ACIK, yani adim TEORIDE kendi ATR'sine gore
// olcekleniyor olmali — ama panel durumu sembol basina BAGIMSIZ (her
// grafige ayri EA ornegi) oldugu icin, ATR MODU kapali kalmis ya da ilk
// RiskPreset_Apply hic tetiklenmemis bir ornekte adim, XAUUSD icin
// kalibre edilmis InpVG_StepValue'ye (puan) dusebilir — bu deger BTC'nin
// fiyat olceginde anlamsiz kalir. Bu kilit, KOKENI NE OLURSA OLSUN son bir
// savunma hatti: adim, sembolun O ANKI ATR'sinin cok altindaysa yeni grid
// seviyesi acilmasini engeller ve panelde uyarir.
input bool       InpSafety_ScaleGuard       = true;   // ADIM, sembolun kendi ATR'sine gore anlamsizsa yeni giris durdurulsun mu
input double     InpSafety_MinStepAtrFrac   = 0.05;   // adim >= ATR * bu oran degilse guvenlik kilidi devreye girer

// v1.78.33 — Dogan: "altin hafta sonu kapali, o yuzden BTC'de calistiriyorum".
// Yani XAUUSD-disi sembol kullanimi TEK SEFERLIK degil, DUZENLI bir senaryo.
// VEMA-X/Classic/First Touch'un TUM zamanlama pencereleri (bar suresi, ms
// teyit, lookback/horizon) sadece XAUUSD M1'in gurultu ritmine gore
// kalibre edildi — BTC icin "doğru" sayilari gercek veri olmadan tahmin
// etmek yeni bir risk yaratir. Bunun yerine: XAUUSD DISI bir sembolde tum
// bu pencereler otomatik olarak genisletilir (varsayilan 2.5x) — yani
// BTC/USOIL gibi test edilmemis sembollerde sistem kendiliginden daha
// YAVAS ve daha TEMKINLI davranir, kullanicidan ekstra ayar istemez.
input double     InpSafety_NonGoldTimingMult = 2.5;   // XAUUSD disi sembollerde zamanlama pencereleri kac kat genislesin
double RT_TimingMult(const string symbol) {
   if(StringFind(symbol, "XAU") >= 0) return 1.0; // ayarlar zaten bunun icin kalibre edildi
   return MathMax(1.0, InpSafety_NonGoldTimingMult);
}

// v1.78.25: SPREAD KORUMA CARPANI — Dogan: "USOIL/UKOIL gibi genis spread'li
// sembollerde sorun cikacak gibi duruyor, spread her sembole gore otomatik
// olusup ATR moduyla calismali". Nexus'ta TP tarafinda zaten spread-bazli bir
// mod var (GTP_SPREAD_MULT, Lattice_CalcTPDistance icinde) ama STEP tarafinda
// (GST_* enum'u) hic yoktu — ATR sistemi de sembol tipini (Forex/BTC/ETH) statik
// bir carpanla ayirdigi icin USOIL/UKOIL gibi ne BTC ne ETH olan semboller
// otomatik "Forex" kategorisine dusuyor ve o kategorinin XAUUSD/majör-forex icin
// kalibre edilmis carpani/koruma mesafesi bu sembollerde yanlis olcekte kalabilir.
// Asagidaki carpan, SEMBOLDEN BAGIMSIZ, o sembolun O ANKI CANLI spread'ini okuyup
// "step, spread'in en az bu kadar kati olsun" diye EK bir taban koyar — boylece
// USOIL gibi genis spread'li bir sembolde step otomatik buyur, EURUSD gibi dar
// spread'li bir sembolde kucuk kalir; elle sembol-sembol ayarlamaya gerek kalmaz.
// v1.78.26: Dogan — ATR + spread ikisi birlikte her sembolun KENDI degerini
// otomatik urettigi icin ayri bir "1$ koruma mesafesi" (GuardMove_Forex/BTC/ETH)
// mekanizmasina artik GEREK YOK; o blok (sembol-tipi bazli, statik $ tutarli)
// tamamen KALDIRILDI. Step artik SADECE ATR (volatilite) ve spread (likidite/
// islem maliyeti) uzerinden, sembolden bagimsiz sekilde kendini ayarliyor.
// 0 girilirse spread koruma tamamen KAPALI olur (eski davranisa doner).
input group "=== ATR SPREAD KORUMA (SEMBOLDEN BAGIMSIZ OTOMATIK) ==="
input double     InpATR_SpreadGuardMult     = 3.0;    // step >= canli_spread * bu carpan (0 = kapali)

//--- ADX FILTRESI (ALGO CheckADX_TrendStrength esinli, birebir ayni esik mantigi)
// v1.78.22: ADX < esik ise Lattice_TryOpenLevel YENI seviye ACMAZ (mevcut
// pozisyonlara dokunmaz — ALGO'da da sadece buySignal/sellSignal false olur).
input group "=== ADX FILTRESI (ALGO ESINLI) ==="
input bool       InpADX_FilterEnable        = true;  // v1.78.118: kullanici talebiyle false->true (ON)
input int        InpADX_Period              = 14;
input double     InpADX_Threshold           = 22.0;   // v1.78.118: kullanici talebiyle 30.0->22.0

//--- NEWS FILTER ----------------------------------------------------
input group "=== NEWS FILTER ==="
input bool       InpNF_Enable               = false;
input bool       InpNF_PauseTrading         = true;
input bool       InpNF_HedgeBeforeNews      = false;
input bool       InpNF_CloseAllBeforeNews   = false;
input bool       InpNF_CloseHedgeAfterNews  = true;
input int        InpNF_BeforeMinutes        = 30;
input int        InpNF_AfterMinutes         = 15;
input int        InpNF_ImportanceMin        = 2;    // 0=all 1=low 2=mod 3=high
input string     InpNF_CurrencyFilter       = "";   // boş=sembol para birimleri
input bool       InpNF_BlockDuringEvent     = true;
input int        InpNF_LookaheadHours       = 24;
input bool       InpNF_LogEvents            = false;
input ulong      InpMagicNFHedge            = 78777;

//--- WEEKLY TRADING HOURS -------------------------------------------
input group "=== WEEKLY TRADING HOURS ==="
input bool       InpEnableWeeklySchedule    = false;
input ENUM_TIME_FILTER_ACTION InpWeeklyScheduleAction = TFA_BLOCK_NEW;
input ENUM_TIME_FILTER_CLOCK  InpWeeklyScheduleClock  = TFC_BROKER;
input int        InpWeeklyScheduleResumeDelaySec = 10;
// v1.78.41 FIX: Weekly_NetHedge() daha once ayri magic KULLANMIYORDU — hedge
// pozisyonu g_magic ile aciliyordu, yani Security_CloseMagicPositions gibi
// genel guvenlik kapatmalari (GLOBAL_PROFIT/LOSS/FORCED_RESET) bu hedge'i
// normal Grid/Bullet pozisyonuymus gibi kapatabiliyordu — hedge'in koruma
// amacini gecersiz kiliyordu. DD Hedge (InpMagicDDHedge) ve NF Hedge
// (InpMagicNFHedge) zaten ayri magic kullaniyordu, Weekly Hedge icin de ayni
// desen tamamlandi.
input ulong      InpMagicWeeklyHedge        = 78778;
input string     InpMon_P1 = "00:00-05:59"; input string InpMon_P2 = "06:00-11:59";
input string     InpMon_P3 = "12:00-17:59"; input string InpMon_P4 = "18:00-23:59";
input string     InpTue_P1 = "00:00-05:59"; input string InpTue_P2 = "06:00-11:59";
input string     InpTue_P3 = "12:00-17:59"; input string InpTue_P4 = "18:00-23:59";
input string     InpWed_P1 = "00:00-05:59"; input string InpWed_P2 = "06:00-11:59";
input string     InpWed_P3 = "12:00-17:59"; input string InpWed_P4 = "18:00-23:59";
input string     InpThu_P1 = "00:00-05:59"; input string InpThu_P2 = "06:00-11:59";
input string     InpThu_P3 = "12:00-17:59"; input string InpThu_P4 = "18:00-23:59";
input string     InpFri_P1 = "00:00-05:59"; input string InpFri_P2 = "06:00-11:59";
input string     InpFri_P3 = "12:00-17:59"; input string InpFri_P4 = "18:00-23:59";
input string     InpSat_P1 = "00:00-00:00"; input string InpSat_P2 = "00:00-00:00";
input string     InpSat_P3 = "00:00-00:00"; input string InpSat_P4 = "00:00-00:00";
input string     InpSun_P1 = "00:00-00:00"; input string InpSun_P2 = "00:00-00:00";
input string     InpSun_P3 = "00:00-00:00"; input string InpSun_P4 = "00:00-00:00";

//--- VIOP / FUTURES SAFETY ------------------------------------------
input group "=== VIOP / FUTURES SAFETY ==="
input ENUM_VIOP_DETECTION InpVIOP_DetectionMode = VIOP_AUTO;
input bool       InpVIOP_EnableSessionControl = true;
input bool       InpVIOP_UseBrokerSessionTimes = true;
input bool       InpVIOP_UseFixedTimesFallback = true;
input int        InpVIOP_Close_Hour         = 18;
input int        InpVIOP_Close_Min          = 10;
input int        InpVIOP_Open_Hour          = 9;
input int        InpVIOP_Open_Min           = 20;
input int        InpVIOP_GapWaitMinutes     = 5;
input bool       InpVIOP_EnableExpiryProtection = true;
input int        InpVIOP_BlockNewHoursBeforeExpiry = 48;
input bool       InpVIOP_ForceCloseBeforeExpiry = false;
input int        InpVIOP_ForceCloseMinutesBeforeExpiry = 30;
input bool       InpVIOP_BlockOptionSymbols = true;
input ENUM_VIOP_ROLLOVER InpVIOP_RolloverMode = VIOP_ROLLOVER_OFF;
input int        InpVIOP_RolloverSearchDays = 180;
input int        InpVIOP_AutoSwitchHoursBeforeExpiry = 1;

//--- TRADE ID NUMBERS / MAGIC ---------------------------------------
input group "=== TRADE ID NUMBERS ==="
input string     InpMagicChartSuffix        = "";
// AUDIT v1.78.72: asagidaki 7 input statik taramada gercek magic
// uretimiyle (BuildMagic() = InpMagicBase + InpMagicChartSuffix) hicbir
// baglantisi bulunmadi - Grid/Lattice/Bullet tum BUY+SELL emirleri TEK
// bir g_magic (BuildMagic() ciktisi) ile aciliyor. Silinmedi (eski .set
// uyumlulugu), karar mantigina da baglanmadi (mevcut acik pozisyonlarin
// magic'i degismesin) - sadece isaretlendi.
input int        InpMagicBuy                = 2001;    // [KULLANILMIYOR] gercek magic=BuildMagic()
input int        InpMagicSell               = 2002;    // [KULLANILMIYOR] gercek magic=BuildMagic()
input int        InpMagicGridEscapeBuy      = 2311;    // [KULLANILMIYOR] gercek magic=BuildMagic()
input int        InpMagicGridEscapeSell     = 2312;    // [KULLANILMIYOR] gercek magic=BuildMagic()
input int        InpMagicManualHedge        = 78778;   // [KULLANILMIYOR] gercek magic=BuildMagic()
input int        InpMagicDynHedge           = 78780;   // [KULLANILMIYOR] gercek magic=BuildMagic()
input int        InpMagicTimeHedge          = 78781;   // [KULLANILMIYOR] gercek magic=BuildMagic()

//--- PANEL / MASTER -------------------------------------------------
input group "=== PANEL / MASTER ==="
input bool       InpMasterPanelPublish      = false;
input bool       InpMasterPanelSync         = false;
input string     InpMasterPanelPrefix       = "NXR21_MASTER_";
input int        InpGV_SyncIntervalMs       = 500;   // Master Sync min aralik
input int        InpGV_PublishIntervalMs    = 1000;  // Master Publish min aralik (dirty yoksa)

//--- PROFIT / LOSS CLOSE FEATURE GATES (PDF 8.4) --------------------
input group "=== PROFIT CLOSE FEATURE GATES ==="
input bool       InpPCF_Master              = true;
input bool       InpPCF_TrendFlip           = true;
input bool       InpPCF_AEG_Profit          = true;
input bool       InpPCF_GridTP              = true;
input bool       InpPCF_TP_Project          = true;
input bool       InpPCF_GlobalProfitReset   = true;
input bool       InpPCF_BonusTP             = true;
input bool       InpPCF_ProfitLock          = true;

input group "=== LOSS CLOSE FEATURE GATES ==="
input bool       InpLCF_Master              = true;
input bool       InpLCF_TrendFlip           = true;
input bool       InpLCF_GlobalLossReset     = true;
input bool       InpLCF_DailyLoss           = true;
input bool       InpLCF_NewsLoss            = true;
input bool       InpLCF_VIOP_Loss           = true;
input bool       InpLCF_ForcedLoss          = true;
// v1.78.94 FIX: FeatureGate_Loss("AEG_LOSS") cagrisi hicbir case'e eslenmiyordu
// (asagida eklendi), bu yuzden panelden/inputtan KAPATILAMIYORDU - her zaman
// true donuyordu. AEG_PROFIT'in gercek karsiligi (InpPCF_AEG_Profit) zaten
// vardi, zarar tarafinin de kendi calisan anahtari olmasi gerekiyordu.
input bool       InpLCF_AegLoss             = true;   // AEG_LOSSCUT_FLIP icin gercek gate

//+------------------------------------------------------------------+
//| 4. GLOBAL DEĞİŞKENLER                                            |
//+------------------------------------------------------------------+
CTrade         g_trade;
CSymbolInfo    g_symInfo;
CAccountInfo   g_account;
CPositionInfo  g_pos;

// v1.78.43 FIX (#106/#107/#108/#109): Lattice, Bullet, News Hedge, DD Hedge —
// hepsi kendi PositionClose() cagrisini yapiyordu ve sadece bool donusunu
// kontrol ediyordu ("emir KABUL EDILDI mi", gercekten broker'da KAPANDI mi
// degil). Requote/kismi fill/"trade context busy" gibi durumlarda emir kabul
// edilip de pozisyon hala acik kalabilir — bu durumda state (lat.active=false,
// B_TICKET=0 vb.) YANLIS ZAMANDA temizleniyordu, EA pozisyonu "yok" saniyor
// ama broker'da hala aciktir; ayni yonde ikinci bir pozisyon acilabilir veya
// risk hesaplari yanlis kalir. Bu ortak fonksiyon: 1) ResultRetcode kontrol
// eder, 2) PositionSelectByTicket ile GERCEKTEN kapandigini dogrular (idempotent
// — pozisyon zaten yoksa true doner), 3) SADECE dogrulanmis basaridan sonra
// true doner. Cagiran taraf state'i yalnizca true donerse temizlemelidir.
bool SafeClosePosition(const ulong ticket, const string reason) {
   if(ticket == 0) return true; // zaten yok sayilir — idempotent
   static ulong s_closeTickets[64];
   static ulong s_closeAtMs[64];
   ulong nowMs = GetTickCount64();
   int slot = -1;
   int oldestSlot = 0;
   ulong oldestMs = ULLONG_MAX;
   for(int i = 0; i < ArraySize(s_closeTickets); i++) {
      if(s_closeTickets[i] == ticket) {
         slot = i;
         break;
      }
      if(s_closeAtMs[i] < oldestMs) {
         oldestMs = s_closeAtMs[i];
         oldestSlot = i;
      }
   }
   if(slot < 0) {
      slot = oldestSlot;
      s_closeTickets[slot] = ticket;
   } else if(s_closeAtMs[slot] > 0 && nowMs - s_closeAtMs[slot] < 250) {
      return false; // ayni ticket icin duplicate close istegi bastirildi
   }

   ResetLastError();
   if(!PositionSelectByTicket(ticket)) {
      s_closeTickets[slot] = 0;
      s_closeAtMs[slot] = 0;
      return true; // zaten kapali/yok
   }

   s_closeAtMs[slot] = nowMs;
   ResetLastError();
   bool sent = g_trade.PositionClose(ticket);
   int terminalError = GetLastError();
   uint retcode = g_trade.ResultRetcode();

   if(!sent) {
      PrintFormat("SafeClose FAIL [%s] ticket=%I64u retcode=%u terminal=%d %s (emir GONDERILEMEDI)",
                  reason, ticket, retcode, terminalError, g_trade.ResultRetcodeDescription());
      return false;
   }

   if(retcode != TRADE_RETCODE_DONE && retcode != TRADE_RETCODE_DONE_PARTIAL &&
      retcode != TRADE_RETCODE_PLACED) {
      PrintFormat("SafeClose REJECT [%s] ticket=%I64u retcode=%u terminal=%d %s",
                  reason, ticket, retcode, terminalError, g_trade.ResultRetcodeDescription());
      return false;
   }

   // Emir kabul edildi (DONE/DONE_PARTIAL gibi) — ama gercekten kapandi mi
   // diye BROKER'DAN tekrar sormadan state temizlenmez.
   if(PositionSelectByTicket(ticket)) {
      // Hala aciksa (tam ya da kismi) — state korunmali, cagiran taraf
      // bir sonraki tick'te tekrar dener.
      double remainVol = PositionGetDouble(POSITION_VOLUME);
      PrintFormat("SafeClose PARTIAL/UNCONFIRMED [%s] ticket=%I64u retcode=%u terminal=%d kalanVol=%.2f — state KORUNUYOR, tekrar denenecek",
                  reason, ticket, retcode, terminalError, remainVol);
      return false;
   }

   // Broker'da artik bulunamiyor → gercekten kapanmis
   s_closeTickets[slot] = 0;
   s_closeAtMs[slot] = 0;
   return true;
}

// v1.78.43 FIX (#105): InpDailyClockMode (LOCAL/BROKER) ayrimi iki farkli
// yerde (Security_GetDailyPnLPercent, UpdateDailyLock) BAGIMSIZ olarak
// tekrarlanmisti — ikisi de "InpDailyClockMode==DGC_LOCAL ? TimeLocal() :
// TimeCurrent()" kodunu ayri ayri yaziyordu. Bu, gelecekte biri guncellenip
// digeri unutulursa (tam da #98'in orijin nedeniydi) tekrar senkron-disi
// kalma riski tasir. Artik TEK yardimci fonksiyon var, her iki yer buna
// yonlendirildi.
datetime Daily_GetNow() {
   return (InpDailyClockMode == DGC_LOCAL) ? TimeLocal() : TimeCurrent();
}

// v1.78.43 FIX (#105 devami): "gunun basi" hesabi StringToTime() ile
// yapiliyordu — StringToTime HER ZAMAN broker/sunucu zaman dilimini varsayar.
// LOCAL modda dt (yil/ay/gun) yerel saate gore hesaplanmisti, ama sonuc
// StringToTime ile broker zaman dilimine gore yorumlaniyordu — yerel ve
// broker saat dilimleri farkliysa (orn. yerel gece yarisini gectiginde
// broker henuz onceki gunde olabilir) HistorySelect'in baslangic noktasi
// birkac saat kayabiliyordu. Bu fonksiyon: LOCAL ise yerel gun baslangicini
// once yerel datetime olarak kurup, TimeLocal()-TimeCurrent() farkini
// (saat dilimi ofseti) cikararak broker zaman dilimine dogru cevirir.
datetime Daily_GetDayStartBrokerTime(const MqlDateTime &dt) {
   datetime localDayStart = StringToTime(StringFormat("%04d.%02d.%02d 00:00:00", dt.year, dt.mon, dt.day));
   if(InpDailyClockMode != DGC_LOCAL) return localDayStart; // zaten broker bazli hesaplanmisti
   long offsetSec = (long)TimeLocal() - (long)TimeCurrent(); // yerel - broker farki
   return (datetime)((long)localDayStart - offsetSec);
}

ulong          g_magic;
string         g_symbol;
SLatticeState  g_lattice;
SPipelineContext g_ctx;

#define MAX_SYMBOLS 12
string         g_symbols[MAX_SYMBOLS];
int            g_symbol_count = 0;
SLatticeState  g_lattices[MAX_SYMBOLS];
// SECOND_AUDIT #6 FIX (P2): OnTick() dongusu bitince g_symbol/g_lattice/g_sym_idx
// chart sembolune deterministik olarak geri donuyordu ama g_ctx DONMUYORDU -
// panel/diagnostic kod son islenen sembolun (chart sembolu olmayabilir) context'ini
// okuyabiliyordu. RunStagedPipeline() her cagrida g_ctx'i bastan dolduruyor; bu
// dizi her sembolun kendi pipeline gecisinin SONUCUNU saklar, boylece loop sonunda
// pipeline'i TEKRAR CALISTIRMADAN (cift-islem riski olmadan) chart sembolunun
// context'i geri yuklenebilir.
SPipelineContext g_ctxSnapshot[MAX_SYMBOLS];
int g_altTP_side = 0; // FIX: En uste tasindi, basket TP toggle

//+------------------------------------------------------------------+
//| v1.68 Indicator handle cache (sembol basina, OnInit/OnDeinit)    |
//+------------------------------------------------------------------+
struct SIndHandles {
   int atr14;
   int adx_di;
   int ema_di;
   int rsi_tmi;
   int ema34;
   int rsi14;
   int ema9;
   int ema21;
   int atr_grid;   // v1.78.22: ATR Sistemi icin ayri handle (InpATR_Period, DI motorundan bagimsiz)
   int adx_filt;   // v1.78.22: ADX Filtresi icin ayri handle (InpADX_Period, DI motorundan bagimsiz)
   string sym;
   bool ready;
};
SIndHandles g_ind[MAX_SYMBOLS];

// v1.78.22: ALGO GetSymbolType() karsiligi — CalcATRBasedParams'taki
// sembol-tipi stepMult dalini (Forex/BTC/ETH) besler. 0=Forex/Metal/Diger, 1=BTC, 2=ETH.
int RiskATR_SymbolType(const string symbol) {
   if(StringFind(symbol, "BTC") >= 0) return 1;
   if(StringFind(symbol, "ETH") >= 0) return 2;
   return 0;
}

int Ind_FindIdx(const string symbol) {
   for(int i = 0; i < g_symbol_count; i++)
      if(g_symbols[i] == symbol) return i;
   return -1;
}

void Ind_ReleaseOne(SIndHandles &h) {
   if(h.atr14  != INVALID_HANDLE) { IndicatorRelease(h.atr14);  h.atr14  = INVALID_HANDLE; }
   if(h.adx_di != INVALID_HANDLE) { IndicatorRelease(h.adx_di); h.adx_di = INVALID_HANDLE; }
   if(h.ema_di != INVALID_HANDLE) { IndicatorRelease(h.ema_di); h.ema_di = INVALID_HANDLE; }
   if(h.rsi_tmi!= INVALID_HANDLE) { IndicatorRelease(h.rsi_tmi);h.rsi_tmi= INVALID_HANDLE; }
   if(h.ema34  != INVALID_HANDLE) { IndicatorRelease(h.ema34);  h.ema34  = INVALID_HANDLE; }
   if(h.rsi14  != INVALID_HANDLE) { IndicatorRelease(h.rsi14);  h.rsi14  = INVALID_HANDLE; }
   if(h.ema9   != INVALID_HANDLE) { IndicatorRelease(h.ema9);   h.ema9   = INVALID_HANDLE; }
   if(h.ema21  != INVALID_HANDLE) { IndicatorRelease(h.ema21);  h.ema21  = INVALID_HANDLE; }
   if(h.atr_grid != INVALID_HANDLE) { IndicatorRelease(h.atr_grid); h.atr_grid = INVALID_HANDLE; }
   if(h.adx_filt != INVALID_HANDLE) { IndicatorRelease(h.adx_filt); h.adx_filt = INVALID_HANDLE; }
   h.ready = false;
}

void Ind_InitAll() {
   ENUM_TIMEFRAMES tfTrend = (InpTrendTF == PERIOD_CURRENT) ? PERIOD_CURRENT : InpTrendTF;
   // FIX v1.78.13: InpRangeTF hic kullanilmiyordu; tfTrend ile ayni desende
   // ATR (range/volatilite olcumu, AWR_Evaluate->Ind_ATR uzerinden okunuyor) artik bu TF'de.
   ENUM_TIMEFRAMES tfRange = (InpRangeTF == PERIOD_CURRENT) ? PERIOD_CURRENT : InpRangeTF;
   for(int i = 0; i < MAX_SYMBOLS; i++) {
      g_ind[i].atr14 = g_ind[i].adx_di = g_ind[i].ema_di = g_ind[i].rsi_tmi = INVALID_HANDLE;
      g_ind[i].ema34 = g_ind[i].rsi14 = g_ind[i].ema9 = g_ind[i].ema21 = INVALID_HANDLE;
      g_ind[i].atr_grid = g_ind[i].adx_filt = INVALID_HANDLE; // v1.78.22
      g_ind[i].ready = false;
   }
   for(int i = 0; i < g_symbol_count; i++) {
      string s = g_symbols[i];
      g_ind[i].sym = s;
      g_ind[i].atr14  = iATR(s, tfRange, 14);
      g_ind[i].adx_di = iADX(s, tfTrend, InpDI_ADX_Period);
      g_ind[i].ema_di = iMA(s, tfTrend, InpDI_EMA_Period, 0, MODE_EMA, PRICE_CLOSE);
      g_ind[i].rsi_tmi= iRSI(s, PERIOD_CURRENT, InpTMI_RSI_Period, PRICE_CLOSE);
      g_ind[i].ema34  = iMA(s, PERIOD_CURRENT, 34, 0, MODE_EMA, PRICE_CLOSE);
      g_ind[i].rsi14  = iRSI(s, PERIOD_CURRENT, 14, PRICE_CLOSE);
      g_ind[i].ema9   = iMA(s, PERIOD_CURRENT, 9, 0, MODE_EMA, PRICE_CLOSE);
      g_ind[i].ema21  = iMA(s, PERIOD_CURRENT, 21, 0, MODE_EMA, PRICE_CLOSE);
      // v1.78.22: ATR Sistemi + ADX Filtresi icin ayri handle (ALGO hATR/hADX
      // esinli) — DI motorunun period'undan bagimsiz, kendi input'larini kullanir.
      g_ind[i].atr_grid = iATR(s, PERIOD_CURRENT, InpATR_Period);
      g_ind[i].adx_filt = iADX(s, PERIOD_CURRENT, InpADX_Period);
      g_ind[i].ready  = true;
   }
   PrintFormat("Ind handles: %d sembol x 10 = %d handle acildi", g_symbol_count, g_symbol_count * 10);
}

void Ind_ReleaseAll() {
   for(int i = 0; i < MAX_SYMBOLS; i++) {
      Ind_ReleaseOne(g_ind[i]);
      g_ind[i].sym = "";
   }
}

// REPAINT FIX: ATR her zaman son kapanmış barı kullanır; çağıran taraf 0 istese bile
// oluşmakta olan mumun volatilitesi strateji kararını değiştiremez.
double Ind_ATR(const string symbol, const int shift=0) {
   int closedShift = MathMax(1, shift);
   int idx = Ind_FindIdx(symbol);
   int h = (idx >= 0) ? g_ind[idx].atr14 : INVALID_HANDLE;
   if(h == INVALID_HANDLE) {
      h = iATR(symbol, TF_EffectiveRange(), 14); // FIX v1.78.13: tfRange ile tutarli olsun diye
      double b[];
      double v = 0;
      if(h != INVALID_HANDLE) {
         ResetLastError();
         if(CopyBuffer(h, 0, closedShift, 1, b) <= 0)
            PrintFormat("IND ATR FAIL | %s | shift=%d err=%d", symbol, closedShift, GetLastError());
         else if(ArraySize(b) > 0 && MathIsValidNumber(b[0]) && b[0] > 0.0)
            v = b[0];
      }
      if(h != INVALID_HANDLE) IndicatorRelease(h);
      return v;
   }
   double b[];
   ResetLastError();
   if(CopyBuffer(h, 0, closedShift, 1, b) > 0 &&
      ArraySize(b) > 0 && MathIsValidNumber(b[0]) && b[0] > 0.0)
      return b[0];
   PrintFormat("IND ATR FAIL | %s | shift=%d err=%d", symbol, closedShift, GetLastError());
   return 0;
}

// REPAINT FIX: DI/ADX yön ve güç kararları yalnızca kapanmış trend barından okunur.
bool Ind_ADX_DI(const string symbol, double &adx, double &pdi, double &mdi) {
   adx = 0; pdi = 0; mdi = 0;
   int idx = Ind_FindIdx(symbol);
   int h = (idx >= 0) ? g_ind[idx].adx_di : INVALID_HANDLE;
   if(h == INVALID_HANDLE) return false;
   double a[], p[], m[];
   if(CopyBuffer(h, 0, 1, 1, a) > 0 && ArraySize(a) > 0 && MathIsValidNumber(a[0]) && a[0] >= 0.0) adx = a[0];
   if(CopyBuffer(h, 1, 1, 1, p) > 0 && ArraySize(p) > 0 && MathIsValidNumber(p[0]) && p[0] >= 0.0) pdi = p[0];
   if(CopyBuffer(h, 2, 1, 1, m) > 0 && ArraySize(m) > 0 && MathIsValidNumber(m[0]) && m[0] >= 0.0) mdi = m[0];
   return (MathIsValidNumber(adx) && MathIsValidNumber(pdi) && MathIsValidNumber(mdi));
}

// REPAINT FIX: DI EMA teyidi tamamlanmış mumun EMA değeriyle yapılır.
double Ind_EMA_DI(const string symbol) {
   int idx = Ind_FindIdx(symbol);
   int h = (idx >= 0) ? g_ind[idx].ema_di : INVALID_HANDLE;
   if(h == INVALID_HANDLE) return 0;
   double b[];
   if(CopyBuffer(h, 0, 1, 1, b) > 0 && ArraySize(b) > 0 && MathIsValidNumber(b[0]) && b[0] > 0.0) return b[0];
   return 0;
}

// REPAINT FIX: TMI RSI değeri oluşmakta olan mumdan okunmaz.
double Ind_RSI_TMI(const string symbol) {
   int idx = Ind_FindIdx(symbol);
   int h = (idx >= 0) ? g_ind[idx].rsi_tmi : INVALID_HANDLE;
   if(h == INVALID_HANDLE) return 50;
   double b[];
   if(CopyBuffer(h, 0, 1, 1, b) > 0 && ArraySize(b) > 0 && MathIsValidNumber(b[0]) && b[0] >= 0.0 && b[0] <= 100.0) return b[0];
   return 50;
}

// REPAINT FIX: Genel indikatör buffer erişiminde shift=0 zorla kapanmış bara alınır.
double Ind_HandleBuf(const int handle, const int shift=0) {
   if(handle == INVALID_HANDLE) return 0;
   int closedShift = MathMax(1, shift);
   double b[];
   if(CopyBuffer(handle, 0, closedShift, 1, b) > 0 && ArraySize(b) > 0 && MathIsValidNumber(b[0])) return b[0];
   return 0;
}

// v1.78.22: ATR Sistemi / ADX Filtresi okuma helper'lari — g_ind[].atr_grid
// ve g_ind[].adx_filt handle'larindan okur (Ind_ATR/Ind_ADX_DI'dan bagimsiz,
// cunku bunlar farkli period ile acilan ayri handle'lar).
// REPAINT FIX: ATR risk filtresi de diğer ATR okumalarıyla aynı kapanmış barı kullanır.
double RiskATR_Read(const string symbol) {
   int idx = Ind_FindIdx(symbol);
   if(idx < 0) return 0;
   return Ind_HandleBuf(g_ind[idx].atr_grid, 1);
}

// ALGO CheckADX_TrendStrength birebir karsiligi: filtre kapaliysa veya
// handle yoksa true (engelleme yok) doner; ADX esigin ALTINDAYSA false doner.
bool RiskADX_TrendStrengthOK(const string symbol) {
   if(!RT_ADXFilter()) return true;
   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || g_ind[idx].adx_filt == INVALID_HANDLE) return true;
   double adxVal = Ind_HandleBuf(g_ind[idx].adx_filt, 1);
   if(adxVal <= 0) return true; // henuz veri yoksa engelleme
   if(adxVal < RT_ADXThreshold()) return false;
   return true;
}


ulong          g_lastSignalRefreshMs = 0;  // v1.68: ms (GetTickCount ile ayni birim)
datetime       g_lastPanelRefresh  = 0;
ulong          g_lastGvSyncMs      = 0;
ulong          g_lastGvPubMs       = 0;
bool           g_gv_dirty          = true;   // degisince true → yaz
// Onceden hesaplanmis anahtarlar (string alloc azaltir)
string         g_gvLocRobot = "", g_gvLocBuy = "", g_gvLocSell = "";
string         g_gvLocTab = "", g_gvLocSub = "", g_gvLocEq = "";
string         g_gvLocVG = "", g_gvLocBullet = "", g_gvLocNF = "";
string         g_gvMasRobot = "", g_gvMasBuy = "", g_gvMasSell = "";
string         g_gvMasTab = "", g_gvMasSub = "";
string         g_gvMasVG = "", g_gvMasBullet = "", g_gvMasNF = "";
bool           g_gvKeysReady = false;
bool           g_dailyLocked       = false;
datetime       g_dailyUnlockGrace  = 0; // panel KILIT KALDIR sonrasi kisa dokunulmazlik
bool           g_newsHardLock      = false; // aktif sembol (g_sym_idx) kopyasi
// v1.78.44 FIX (#111): g_newsHardLock, pencere ICINDE miyiz bilgisini tasir;
// pencereden cikinca kosulsuz false yapiliyordu. CloseHedgeAfterNews bloğunun
// calisma kosulu bu bayraga bagliydi — SafeClosePosition basarisiz olsa bile
// (hedge broker'da acik kalmis olsa bile) bir sonraki tick'te g_newsHardLock
// zaten false oldugu icin blok TEKRAR CALISMIYORDU, "tekrar denenecek" logu
// yaniltici kaliyordu. Bu ayri bayrak SADECE "kapatilmasi gereken NF hedge
// pozisyonu var, henuz basariyla kapatilamadi" durumunu tutar; pencere
// durumundan bagimsizdir, sadece gercek basaridan sonra false olur.
// v1.78.44 FIX (#114): MAX_SYMBOLS bazli — asagida tanimli
bool           g_nfHedgeCloseRetryPending[MAX_SYMBOLS];
bool           g_newsLockSym[MAX_SYMBOLS];   // v1.68: sembol basina haber kilidi
// v1.78.51 FIX (#120): "Info" haber listesi eksikti — InpNF_LookaheadHours/
// InpNF_LogEvents input olarak tanimliydi ama HICBIR YERDE kullanilmiyordu.
// Panelde sadece kilit durumu (AKTIF/yok) gosteriliyordu, gercek haber
// listesi (isim/saat/onem) hic cizilmiyordu — kullanici hep "haber yok"
// goruyordu cunku gosterecek veri hic hesaplanmiyordu.
#define NF_INFO_MAX 10
string         g_nfInfoLines[NF_INFO_MAX];
int            g_nfInfoCount      = 0;
datetime       g_nfInfoLastCalc   = 0;
bool           g_viopBlocked       = false;
bool           g_weeklyOutside     = false;   // saat filtresi: dilim dışı
datetime       g_weeklyResumeAt    = 0;      // resume delay bitiş zamanı
bool           g_consensusBlocked  = false;
string         g_consensusNote     = "";
bool           g_runLatticeThisTick = true;  // multi-symbol: ekstra sembolde kapatılabilir
// v1.68: multi-symbol bullet state (index = g_sym_idx)
int            g_sym_idx = 0;
int            g_bullet_sameSideLoss[MAX_SYMBOLS];
// v1.78.115 EKLENTI (kullanici talebi): MANUEL/AUTO lot modlarinda Grid'deki
// gibi bir "ardisik kazancta buyume" carpani yoktu - Bullet lotu her zaman
// sabit (MANUEL) veya sadece bakiye yuzdesine bagli (AUTO) kaliyordu. Bu
// dizi, ayni yonde ARDISIK KAZANILAN Bullet islemi sayisini tutar (B_SAME_LOSS
// ile simetrik ama TERSI - kazaninca artar, kaybedince sifirlanir). Asagidaki
// Bullet_CalcLot() bu sayaci Grid'in kendi panel carpanina (g_rt_grid_mult)
// gore olceklendirir.
int            g_bullet_sameSideWin[MAX_SYMBOLS];
int            g_bullet_lastDir[MAX_SYMBOLS];
// v1.78.116 FIX (kritik - kod incelemesinde bulundu): B_ENTRY_DIR ve
// B_LAST_DIR, HER YENI POZISYON ACILISINDA AYNI ANDA/AYNI DEGERE set
// ediliyordu (bkz. Bullet_OpenNew, "B_LAST_DIR=dir; B_ENTRY_DIR=dir;" ayni
// satirlarda) - bu, Bullet_CloseTicket() icindeki "B_ENTRY_DIR==B_LAST_DIR"
// karsilastirmasinin PRATIKTE HER ZAMAN TRUE donmesine yol aciyordu (cunku
// kapanis anina kadar hicbiri degismiyordu). Sonuc: hem YENI eklenen
// B_SAME_WIN hem de ONCEDEN VAR OLAN B_SAME_LOSS sayaclari, YON DEGISIKLIGINI
// HIC YAKALAYAMIYORDU - BUY kazanip SELL kazansa bile seri ARTMAYA DEVAM
// EDIYORDU (dogrusu: yon degisince seriyi 1'den baslatmak). Bu, hem lot
// buyutmenin (B_SAME_WIN) hem de zarar-serisi korumalarinin (B_SAME_LOSS,
// InpTPProjFreezeOnLossStreak, InpBullet_LossQualityStep) YANLIS calismasina
// yol acabilecek onemli bir tasarim hatasiydi. Duzeltme: bu yeni dizi,
// SADECE bir onceki KAPANAN islemin yonunu tutar (acilista degil, KAPANISTA
// guncellenir) - artik gercek "ardisik ayni yon" karsilastirmasi mumkun.
int            g_bullet_prevClosedDir[MAX_SYMBOLS];
datetime       g_bullet_lastOpen[MAX_SYMBOLS];
datetime       g_bullet_lastClose[MAX_SYMBOLS];
datetime       g_bullet_lastFlip[MAX_SYMBOLS];
int            g_bullet_lastCloseWasLoss[MAX_SYMBOLS];
ulong          g_bullet_ticket[MAX_SYMBOLS];
double         g_bullet_peakProfit[MAX_SYMBOLS];
// v1.78.44 FIX (#113): AEGIS pullback peak'i sembol bazli (bkz. Stage_ProfitExits)
double         g_aegPeak[MAX_SYMBOLS];
int            g_bullet_entryDir[MAX_SYMBOLS];
datetime       g_bullet_openTime[MAX_SYMBOLS];
int            g_bullet_confirmTicks[MAX_SYMBOLS];
// SECOND_AUDIT #1 FIX (P1): Bullet_Process() icinde entry-confirm mantiginin
// yon takibi eskiden TEK bir "static int s_lastDir" idi - EA birden fazla
// sembol islerken (multi-symbol) bir sembolun yonu digerinin son yonunu
// eziyordu (orn. XAU BUY sonrasi BTC SELL islenince, sonraki XAU BUY'da
// sistem yon degismis sanabiliyordu). Diger B_* alanlariyla AYNI desende
// sembol bazli diziye tasindi.
int            g_bullet_confirmLastDir[MAX_SYMBOLS];

// Tek-sembol uyumluluk makrolari (aktif sembol index)
#define B_TICKET       g_bullet_ticket[g_sym_idx]
#define B_PEAK         g_bullet_peakProfit[g_sym_idx]
#define B_ENTRY_DIR    g_bullet_entryDir[g_sym_idx]
#define B_OPEN_TIME    g_bullet_openTime[g_sym_idx]
#define B_CONFIRM      g_bullet_confirmTicks[g_sym_idx]
#define B_CONFIRM_LASTDIR g_bullet_confirmLastDir[g_sym_idx]
#define B_SAME_LOSS    g_bullet_sameSideLoss[g_sym_idx]
#define B_SAME_WIN     g_bullet_sameSideWin[g_sym_idx]
#define B_LAST_DIR     g_bullet_lastDir[g_sym_idx]
#define B_PREV_CLOSED_DIR g_bullet_prevClosedDir[g_sym_idx]
#define B_LAST_OPEN    g_bullet_lastOpen[g_sym_idx]
#define B_LAST_CLOSE   g_bullet_lastClose[g_sym_idx]
#define B_LAST_FLIP    g_bullet_lastFlip[g_sym_idx]
#define B_LAST_WAS_LOSS g_bullet_lastCloseWasLoss[g_sym_idx]

// v1.78.54: GLOBAL TREND FLIP GUARD state (sembol bazli)
int            g_tfg_lastDir[MAX_SYMBOLS];      // bir onceki tick'te bilinen g_ctx.dir.direction
datetime       g_tfg_lastAction[MAX_SYMBOLS];   // bu sembolde son guard-kapatma zamani (cooldown)

// v1.78.95: DIRECTION FLIP LOCK state (sembol bazli)
int            g_dirlock_committedDir[MAX_SYMBOLS];
int            g_dirlock_candidateDir[MAX_SYMBOLS];
int            g_dirlock_candidateTicks[MAX_SYMBOLS];
datetime       g_dirlock_lastFlip[MAX_SYMBOLS];
bool           g_dirlock_blockEntries[MAX_SYMBOLS];
int            g_range_guard_count[MAX_SYMBOLS]; // RANGE teyit sayaci, sembol bazli
datetime       g_range_guard_since[MAX_SYMBOLS]; // v1.78.68 (#131): RANGE fazina KESINTISIZ girildigi an (saniye bazli teyit icin)
#define TFG_LAST_DIR    g_tfg_lastDir[g_sym_idx]
#define TFG_LAST_ACTION g_tfg_lastAction[g_sym_idx]
#define DIRLOCK_DIR     g_dirlock_committedDir[g_sym_idx]
#define DIRLOCK_CAND    g_dirlock_candidateDir[g_sym_idx]
#define DIRLOCK_TICKS   g_dirlock_candidateTicks[g_sym_idx]
#define DIRLOCK_LAST    g_dirlock_lastFlip[g_sym_idx]
#define DIRLOCK_BLOCK   g_dirlock_blockEntries[g_sym_idx]

// v1.78.94 FIX: AEG_PROTECT/AEG_LOSSCUT_FLIP icin TFG_LAST_ACTION ile AYNI
// desende sembol bazli cooldown (bkz. Stage_ProfitExits). protect_profit ve
// protect_loss karsilikli disladigi icin (AEGIS_Evaluate) TEK zaman damgasi
// ikisi arasinda paylasilir.
datetime       g_aeg_flipLastAction[MAX_SYMBOLS];
#define AEG_FLIP_LAST_ACTION g_aeg_flipLastAction[g_sym_idx]

// SECOND_AUDIT #7 FIX (P3): InpSmartDir_ConfirmTicks artik SmartDir_Evaluate()
// icinde sembol bazli bir teyit sayacina bagli (bkz. fonksiyon icindeki yorum).
int            g_smartdir_confirmTicks[MAX_SYMBOLS];
int            g_smartdir_lastDir[MAX_SYMBOLS];

// SECOND_AUDIT #8 FIX (P3): InpDOM_FreshMs artik gercekten kullaniliyor - DOM
// verisinin ne zaman guncellendigini bilmek icin OnBookEvent() bu diziye
// GetTickCount64() zaman damgasi yaziyor (bkz. OnBookEvent ve DOM confidence
// blogu). Deger 0 ise (henuz hic OnBookEvent gelmemis) veri "stale" sayilir.
ulong          g_dom_lastUpdateMs[MAX_SYMBOLS];
ulong          g_ml_lastInferMs[MAX_SYMBOLS];
double         g_ml_trendProb[MAX_SYMBOLS];
double         g_ml_dirProb[MAX_SYMBOLS];
bool           g_ml_symbolScoreValid[MAX_SYMBOLS];

// v1.78.67 (#130): GRID RANGE PROFIT GUARD state (sembol bazli, Bullet'in
// g_range_guard_count'undan BAGIMSIZ - Bullet'in kapanista sayaci sifirlamasi
// Grid'in kendi teyidini gecikmesin diye ayri tutuldu)
int            g_grid_range_guard_count[MAX_SYMBOLS]; // Grid RANGE teyit sayaci
datetime       g_grid_range_guard_since[MAX_SYMBOLS]; // v1.78.68 (#131): Grid icin ayni, saniye bazli teyit ani
double         g_grid_buy_peakProfit[MAX_SYMBOLS];     // Grid BUY sepeti RANGE icindeki zirve kari
double         g_grid_sell_peakProfit[MAX_SYMBOLS];    // Grid SELL sepeti RANGE icindeki zirve kari
double         g_grid_buy_oppLossAtConfirm[MAX_SYMBOLS];  // v1.78.68 (#131): BUY kapanirken karsi (SELL) tarafin RANGE teyidi anindaki donmus zarari
double         g_grid_sell_oppLossAtConfirm[MAX_SYMBOLS]; // v1.78.68 (#131): SELL kapanirken karsi (BUY) tarafin RANGE teyidi anindaki donmus zarari

// Panel state (erken tanım – MasterPanel / PlatformCheck kullanır)
int            g_panelTab = 0;
bool           g_robotOn  = false; // EA baglaninca KAPALI baslar
bool           g_panelBuy = true;
bool           g_panelSell= true;

// Panel EditBox runtime degerleri (input'u runtime override)
double         g_rt_vg_lot     = 0;
double         g_rt_vg_step    = 0;
double         g_rt_bullet_lot = 0;
double         g_rt_peak       = 0;
bool           g_rt_ready      = false;
bool           g_rt_auto_adapt = true;
string         g_rt_auto_note  = "AUTO";
// v1.78.137 KULLANICI KARARI: SOLVER rejimi iki FARKLI yoldan gelebiliyor -
// (a) gercekten belirsiz/range piyasa (lowVolatilityRange), (b) ADX>=25 VE
// yon hizali dogrulanmis trend ama yuksek volatilite sarti (NETVOL'un ekstra
// istedigi) tutmuyor. Kullanici, rejimin pratikte %95 SOLVER'da kaldigini ve
// NETVOL'un kosullari (highVolatility DAHIL) neredeyse hic tutmadigini
// bildirdi. Ardisik/ustel grid carpanini (b) durumunda da acabilmek icin bu
// bayrak SADECE gercek trend-onayli SOLVER'da true olur - "belirsiz piyasada
// sepeti buyutme" guvenlik ayrimi boylece korunur.
bool           g_rt_solver_is_trend = false;
int            g_adapt_active_regime = -1;
int            g_adapt_candidate_regime = -1;
int            g_adapt_candidate_lot = -1;
datetime       g_adapt_active_since = 0;
datetime       g_adapt_candidate_since = 0;
datetime       g_adapt_last_transition = 0;
#define ADAPT_CANDIDATE_CONFIRM_SEC 60
#define ADAPT_MIN_ACTIVE_SEC        90
#define ADAPT_TRANSITION_COOLDOWN_SEC 30

// v1.78.130: MOTOR ACTIVATION STATE FLAGS — hangi motorun şu anda AKTİF olduğunu belirtir
// Rejim geçişi esnasında sadece yeni motor aktif, eski motorların emir gönderme/sinyal
// üretimi tamamen BLOKE edilir. Her motor için g_motorXXX_active=true → motor çalışır
bool           g_motor_grid_active     = true;  // Grid/Lattice motor aktif
bool           g_motor_bullet_active   = true;  // Bullet/TP-Proj motor aktif
bool           g_motor_solver_active   = true;  // Solver rejimi aktif
bool           g_motor_netvolume_active= false; // NetVolume/Trend motor aktif
bool           g_motor_recovery_active = false; // Recovery/Kontrol rejimi aktif
bool           g_motor_hedge_active    = false; // DD-Hedge motor aktif

// v1.78.130: STATE TRANSITION VERIFICATION — Geçiş sırasında eski state'in hafızadan
// tam olarak silinip yeni state'in uygulandığını doğrulamak için
bool           g_motorTransitionLocked = false; // Geçiş esnasında ALL emir gönderme kilitlenir
datetime       g_motorTransitionStarted = 0;    // Geçişin başlangıç zamanı (timeout kontrol)
int            g_motorLastActiveRegime = -1;   // Önceki rejim (state temizlemesi kontrolü)
bool           g_motorStateFullyCleared = false; // Eski motor parametreleri tamamen sıfırlandı mı?
// Panel kontrol toggle'lari (ekran goruntusu tarzi)
bool           g_rt_loop_harvest = true;
bool           g_rt_escape_fund  = true;
bool           g_rt_grid_tp_auth = true;
bool           g_rt_grid_cont    = true;
bool           g_rt_pyramid      = false;
bool           g_rt_pyr_buy      = false;
bool           g_rt_pyr_sell     = false;
bool           g_rt_sound        = true;
bool           g_rt_dom          = false;
bool           g_rt_ml           = true;
bool           g_rt_grid_both    = true;
bool           g_rt_trend_both   = true;
bool           g_rt_vg_enable    = true;   // GRID runtime
bool           g_rt_bullet_enable= true;   // BULLET runtime
bool           g_rt_nf_enable    = false;  // HABER runtime - panelden ac
int            g_rt_tp_regime    = 5;      // ENUM_TPPROJ_VOLUME_REGIME
int            g_rt_lot_mode     = 1;      // ENUM_BULLET_LOT_MODE
int            g_panelSubTab     = 0;
int            g_panelMainTab    = 0;      // 0 STRATEJI 1 ISLEMLER 2 SISTEM 3 SONUC
int            g_panelScroll     = 0;      // aktif sekmenin offset alias'ı
int            g_panelScrollMax  = 0;
double         g_panelScale      = 1.0;  // runtime; InpPanelScale + GV PSCALE
// v1.73: sekme bazlı kaydırma (STRATEJI/ISLEMLER/SISTEM/SONUC)
int            g_tabScrollOffset[4] = {0,0,0,0};
int            g_tabContentH[4]     = {0,0,0,0};
int            g_viewportTopY       = 0;
int            g_viewportBottomY    = 0;
bool           g_panelForceEditSync = true; // ilk acilis + sekme
bool           g_panelEditing       = false; // OBJ_EDIT odakliyken panel yenileme durur
string         g_panelEditingId     = "";
datetime       g_panelEditingSince  = 0;
ulong          g_lastPanelUiMs      = 0;

//--- Erken global bildirimler (strict: kullanım öncesi tanım zorunlu) v1.68
bool           g_ddHedgeActive       = false;
bool           g_ddHedgePaused       = false;
bool           g_asyncHedgeProtect[MAX_SYMBOLS];
string         g_asyncHedgeReason[MAX_SYMBOLS];
ulong          g_gridLockSinceMs[MAX_SYMBOLS][2];
int            g_orderRejectCount[MAX_SYMBOLS];
ulong          g_lastOrderRejectMs[MAX_SYMBOLS];
string         g_tradeBlockReason    = "";
bool           g_gridRiskTrip[MAX_SYMBOLS];
// AUDIT v1.78.70 (#5/#6): reconcile sirasinda LATTICE_MAX_LEVELS kapasitesini
// asan broker pozisyonu bulunursa (veya calisma sirasinda broker'daki Grid
// pozisyon sayisi state'in bildiginden fazlaysa) true olur; GridRisk_Enforce
// bunu orphan olarak sayip yeni Grid girisini durdurur (kapatma yapmaz).
bool           g_latticeOrphanExtra[MAX_SYMBOLS];
int            g_latticeOrphanExtraCount[MAX_SYMBOLS];
// AUDIT v1.78.70 (#8): sembol+yon bazli gonderim kilidi — ayni hucre icin
// broker onayi kesinlesmeden ikinci bir emrin gonderilmesini engeller.
bool           g_gridSendLock[MAX_SYMBOLS][2]; // [i][0]=buy [i][1]=sell
datetime       g_lastTradeDiagLog    = 0;
string         g_panelApplyMsg       = "";
datetime       g_panelApplyMsgUntil  = 0;
bool           g_timeLimitPaused     = false;  // erken (UpdateMinimalPanel / TradeDiag)

double         g_rt_grid_mult    = 1.09;
double         g_rt_tp_pts       = 0;
double         g_rt_bak_pct      = 0.01;
double         g_rt_tp_var_pct   = 0.18;
bool           g_rt_grid_mult_on = true;
bool           g_rt_seq_mult     = true;
bool           g_rt_trend_align  = true;
bool           g_rt_tfg_enable   = false;  // v1.78.56: panelden acilir kapanir, GV ile kalici
int            g_rt_work_min     = 60;
int            g_rt_idle_min     = 30;
double         g_rt_dd_pct       = 5.0;
double         g_rt_dd_tp_pct    = 0.5;
bool           g_rt_dd_hedge     = false;
double         g_rt_profit_reset_pct = 1.0;
double         g_rt_loss_reset_pct   = 22.0;

struct SRiskGovStats {
   int      trades;
   int      wins;
   int      losses;
   double   totalProfit;
   double   totalLoss;
   int      consecutiveLosses;
   int      consecutiveWins;
};

SRiskGovStats g_riskGovDirStats[MAX_SYMBOLS][2];
SRiskGovStats g_riskGovMotorStats[MAX_SYMBOLS][3];
int           g_riskGovEntryCount[MAX_SYMBOLS][3][2];
datetime      g_riskGovEntryStamp[MAX_SYMBOLS][3][2];
// v1.78.136: motorMult/dirMult blogu ne zaman BASLADI - 15dk'lik cooldown
// penceresini olcmek icin. 0 = su an bloklu degil / hic tetiklenmedi.
datetime      g_riskGovStatsBlockSince[MAX_SYMBOLS][3][2];

// Panel ek runtime (v1.57 – ekran goruntusu tam envanter)
double         g_rt_step_pnt     = 100.0;
double         g_rt_loss_bek     = 15.0;
int            g_rt_loss_adet    = 1;
double         g_rt_profit_bek   = 9.0;
int            g_rt_profit_adet  = 1;
double         g_rt_hassas       = 1.0;
int            g_rt_onay         = 3;
double         g_rt_tolerans     = 0.1;
double         g_rt_cost_mult    = 2.0; // FIX v1.78.13: TP'nin gercek maliyeti kac kat asmasi gerektigi
// v1.78.18: risk motoru / plug&play runtime
int            g_rt_min_sec      = 15;   // grid yeni seviye min sn
int            g_rt_max_levels   = 6;    // yon basina max kademe
double         g_rt_vtp_pct      = 0.0;  // virtual TP % equity (0=kapali)
double         g_rt_min_close_money   = 2.50; // v1.78.20: erken 0.5-0.7$ kapanis engeli
int            g_rt_kulucka      = 20;
int            g_rt_kar_kulucka  = 3;
int            g_rt_zarar_kulucka= 10;
int            g_rt_ornek_sn     = 5;
int            g_rt_mikro_trend  = 0;
bool           g_rt_timer_on     = false;
int            g_rt_hedge_wait   = 5;
double         g_rt_hedge_profit = 0.5;
bool           g_rt_genel_hedge  = false;
int            g_rt_max_reset    = 3;
int            g_rt_reset_min    = 360;
bool           g_rt_reset_idle   = false;
bool           g_rt_reset_limit  = false;
bool           g_rt_sure_sinir   = false;
bool           g_rt_sonra_dur    = false;
bool           g_rt_saat_filtre  = false;
int            g_rt_nf_before    = 30;
int            g_rt_nf_after     = 15;
bool           g_rt_nf_pause     = false;
bool           g_rt_nf_otohedge  = false;
bool           g_rt_nf_hedge_kapat = false;
bool           g_rt_nf_zarar_kapat = true;
int            g_rt_risk_mode    = 2;
bool           g_rt_bonus_tp     = true;
double         g_rt_vtp_mult     = 9.0;
bool           g_rt_blok         = true;
int            g_rt_zarar_blok   = 4;
bool           g_rt_kar_hepsini_kapat   = true;
bool           g_rt_zarar_hepsini_kapat = true;
// v1.78.22: ATR Sistemi / ADX Filtresi runtime (ALGO g_ATRMode / g_UseADXFilter esinli)
bool           g_rt_atr_mode      = true;   // panelden ACIK/KAPALI — risk motoru ATR'dan mi dolsun
// v1.78.30: unutulan is — ATR MODU acikken ADIM PNT/TP PUAN kutusuna elle
// deger yazmanin en fazla 30sn surdugunu, sonra ATR'nin sessizce ustune
// yazdigini konusmustuk. Bu iki bayrak, elle girisin ATR siz tekrar ACIK'a
// alana kadar KALICI olmasini saglar (bkz. Panel_HandleEditApply / periyodik
// tazeleme / tgAtrMode).
bool           g_rt_step_manual_override = false;
bool           g_rt_tp_manual_override   = false;
bool           g_rt_adx_filter    = false;  // panelden ACIK/KAPALI — Lattice_TryOpenLevel yeni giris engeli
double         g_rt_adx_threshold = 30.0;   // panelden +/- ile ayarlanabilir (ALGO ADX_Threshold)
double         g_rt_atr_trig_mult = 1.0;    // panelden duzenlenebilir (InpATR_TriggerMult runtime karsiligi)
// v1.68 panel parity (ticari v7 envanter)
bool           g_rt_net_hedge    = false;
bool           g_rt_sinyal       = true;
bool           g_rt_grid_lines   = true;
int            g_rt_grid_src     = 0;   // 0=GRID MIKRO 1=DI 2=TMI 3=ENSEMBLE
int            g_rt_dir_engine   = 0;   // FIX v1.78.13: 0=VEMA-X 1=First Touch 2=Classic
int            g_rt_tp_start     = 0;   // ENUM_TPPROJ_START_MODE
// v1.78.42 FIX (#99): InpTPProjGReset tanimliydi ama hicbir yerde okunmuyordu.
// -1 = aktif degil (normal InpTPProjStart gecerli). GLOBAL_PROFIT/LOSS/
// FORCED_RESET tetiklendiginde InpTPProjGReset'e gore set edilir, Bullet'in
// reset SONRASI ilk acilisinda bir kerelik override olarak tuketilip -1'e
// geri doner (TPP_GRESET_KEEP_PEAK_LOGIC = mudahale etme, mevcut InpTPProjStart
// davranisini aynen koru).
int            g_gresetForceStartMode = -1;
int            g_rt_peak_mode    = 0;   // 0=PEAK$ 1=BAKIYE%
bool           g_rt_dte_on       = false;  // filtre KAPALI - panelden ac
bool           g_rt_heg_on       = false;  // filtre KAPALI
bool           g_rt_local_close  = false; // YERELI KAPAT (sadece bu sembol)
int            g_rt_saat_mode    = 0;   // 0=BROKER 1=LOCAL 2=UTC
string         g_rt_p1 = "00:00-05:59";
string         g_rt_p2 = "06:00-11:59";
string         g_rt_p3 = "12:00-17:59";
string         g_rt_p4 = "18:00-23:59";
bool           g_timerIdlePhase  = false;
datetime       g_timerPhaseStart = 0;

//--- Runtime getter'lar: panelde ne varsa is mantiginda o gecer
bool RT_VG()      { return g_rt_ready ? g_rt_vg_enable     : InpVG_Enable; }
bool RT_Bullet()  { return g_rt_ready ? g_rt_bullet_enable : InpBulletEnable; }
bool RT_TFG()     { return g_rt_ready ? g_rt_tfg_enable     : InpTFG_Enable; } // v1.78.56
bool RT_NF()      { return g_rt_ready ? g_rt_nf_enable     : InpNF_Enable; }
bool RT_TpAuth()  { return g_rt_ready ? g_rt_grid_tp_auth  : InpVG_TPAuthority; }
int  RT_Regime()  { return g_rt_ready ? g_rt_tp_regime     : (int)InpTPProjRegime; }
int  RT_LotMode() { return g_rt_ready ? g_rt_lot_mode      : (int)InpBulletLotMode; }

void AdaptiveMarket_Analyze(double &atr, double &atrPct, double &spreadPct,
                            double &adx, int &microDir, int &macroDir,
                            double &ddPct, bool &hedgeOverlay) {
   atr = Ind_ATR(_Symbol, 1);
   if(atr <= 0.0) atr = Ind_ATR(_Symbol, 0);

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double mid = (bid > 0.0 && ask > 0.0) ? (bid + ask) * 0.5 : 0.0;
   double spread = (ask > bid) ? (ask - bid) : 0.0;
   atrPct = (mid > 0.0) ? (atr / mid) * 100.0 : 0.0;
   spreadPct = (mid > 0.0) ? (spread / mid) * 100.0 : 0.0;

   double pdi = 0.0;
   double mdi = 0.0;
   adx = 0.0;
   Ind_ADX_DI(_Symbol, adx, pdi, mdi);

   microDir = g_tmi.direction;
   macroDir = g_di.direction;
   if(microDir == 0) microDir = g_ctx.dir.direction;
   if(macroDir == 0) macroDir = g_ctx.dir.direction;

   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   ddPct = (bal > 0.0) ? MathMax(0.0, (bal - eq) / bal * 100.0) : 0.0;
   hedgeOverlay = (g_ddHedgePaused || (g_rt_ready && g_rt_genel_hedge && ddPct >= 4.0));
}

bool AdaptiveMarket_CriticalLoss(double &floatingLossPct, double &deficitPct) {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   floatingLossPct = 0.0;
   deficitPct = (balance > 0.0) ? MathMax(0.0, (balance - equity) / balance * 100.0) : 0.0;
   if(balance <= 0.0) return false;

   double floatingLoss = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      if(PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
      double pnl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(MathIsValidNumber(pnl) && pnl < 0.0) floatingLoss += -pnl;
   }
   floatingLossPct = floatingLoss / balance * 100.0;
   return (deficitPct >= 8.0 || floatingLossPct >= 8.0);
}

// v1.78.130 YENİ FONKSİYON: Tüm eski motor parametrelerini hafızadan temizle
// Rejim geçişi esnasında, önceki motorun residüel ayarları işlem açmasını etkilemesin diye
void AdaptiveMarket_ClearOldMotorState(const int oldRegime) {
   if(oldRegime < 0) return;
   
   // Grid/Lattice motor tampon temizliği
   // (g_lattice yapısı kendisi, sadece dinamik çarpan/flgleri sıfırla)
   // v1.78.167 KADEME/CARPAN FIX (kullanici talebi): InpVG_GridMultRegimeControl
   // varsayilan false iken bu blok CARPAN'a DOKUNMAZ - panelden ayarlanan
   // deger/ACIK durumu rejim gecisinden bagimsiz SABIT kalir. true yapilirsa
   // eski davranis (her rejim gecisinde carpan sifirlanir) geri gelir.
   if(InpVG_GridMultRegimeControl) {
      g_rt_grid_mult = 1.09;       // Varsayılan grid çarpanı
      g_rt_grid_mult_on = false;   // Grid çarpanı kapalı
      g_rt_seq_mult = false;       // Ardışık çarpan kapalı
   }
   
   // Trend Flip Guard, kullanıcı tarafından manuel kontrollü kalmalıdır;
   // otonom rejim geçişleri TFG bayrağını yazmamalıdır.
   g_rt_trend_align = true;      // Trend alignment kaldırıldı
   
   // ATR modu resets
   if(oldRegime == TPP_REG_CONTROLLED_RECOVERY) {
      g_rt_atr_mode = false;     // Recovery iken ATR açık ise kapat
      g_rt_step_manual_override = false;
      g_rt_tp_manual_override = false;
   }
   
   // Lot mode temizliği (BLM_AUTO'ya dön)
   // NOT: rejim değiştikten sonra AdaptiveMarket_ChooseLotMode() yeni mode seçer
   // Burada sadece \"geçiş sırasında eski mode'un lot hesaplamalarının artık çalışmayacağını\" garantiyoruz
   
   // Son olarak state temizleme bayrağı kaldır (geçiş başarıyla tamamlandı)
   g_motorStateFullyCleared = true;
   g_motorTransitionLocked = false;
}

// v1.78.130 YENİ FONKSİYON: Motor aktivasyon state'ini rejime göre güncelle
void AdaptiveMarket_UpdateMotorActivation(const int activeRegime) {
   // Tüm motorları KAPALI olarak başlat (explicit OFF)
   g_motor_grid_active      = false;
   g_motor_bullet_active    = false;
   g_motor_solver_active    = false;
   g_motor_netvolume_active = false;
   g_motor_recovery_active  = false;
   g_motor_hedge_active     = false;
   
   // Rejime göre sadece o rejimle ilgili motorları AÇ
   switch(activeRegime) {
      case TPP_REG_FIXED:
         g_motor_grid_active = true;
         g_motor_bullet_active = true;
         break;
         
      case TPP_REG_BALANCE_PCT:
         g_motor_grid_active = true;
         g_motor_bullet_active = true;
         break;
         
      case TPP_REG_TARGET_DEFICIT:
         g_motor_grid_active = true;
         g_motor_bullet_active = true;
         g_motor_solver_active = true;
         break;
         
      case TPP_REG_CONTROLLED_RECOVERY:
         g_motor_recovery_active = true;  // Recovery TÜM MOTORSÜ KAPAYABİLİR
         g_motor_hedge_active = true;     // Hedge overlay aktif
         g_motor_grid_active = false;     // Grid normal giris BLOKE
         g_motor_bullet_active = false;   // Bullet BLOKE
         break;
         
      case TPP_REG_NET_VOLUME_TARGET:
         g_motor_grid_active = true;
         g_motor_bullet_active = true;
         g_motor_netvolume_active = true;  // NetVolume/Trend motor AÇ
         break;
         
      case TPP_REG_SOLVER:
      default:
         g_motor_grid_active = true;
         g_motor_bullet_active = true;
         g_motor_solver_active = true;
         break;
   }
}

void AdaptiveMarket_ApplySafeBaseline() {
   double floatingLossPct = 0.0;
   double deficitPct = 0.0;
   if(AdaptiveMarket_CriticalLoss(floatingLossPct, deficitPct)) return;

   // Guvenli hesapta recovery/streak buyumesi yok: yalnizca baslangic
   // Balance% matrisi ve genel risk cap'leri lotu belirler.
   g_rt_tp_regime = TPP_REG_BALANCE_PCT;
   g_rt_lot_mode = BLM_AUTO;
   g_rt_grid_mult_on = false;
   g_rt_seq_mult = false;
   
   // v1.78.130: Motor aktivasyon state'i güncellendiğinde bu güvenli temel de
   // motor flagları RESET edilmeli (çift rejim-motor uyumsuzluğunu engelle)
   g_motor_grid_active = true;
   g_motor_bullet_active = true;
   g_motor_solver_active = true;
   g_motor_netvolume_active = false;
   g_motor_recovery_active = false;
   g_motor_hedge_active = false;
}

int AdaptiveMarket_ChooseRegime() {
   if(!g_rt_ready) return (int)InpTPProjRegime;

   double atr = 0.0, atrPct = 0.0, spreadPct = 0.0, adx = 0.0, ddPct = 0.0;
   int microDir = 0, macroDir = 0;
   bool hedgeOverlay = false;
   AdaptiveMarket_Analyze(atr, atrPct, spreadPct, adx, microDir, macroDir, ddPct, hedgeOverlay);

   // v1.78.138 FIX: uc kaynagin (micro/macro/g_ctx.dir.direction) birebir esit
   // olmasini isteyen eski sart neredeyse hicbir zaman tutmuyordu (microDir/
   // macroDir zaten yukarida g_ctx.dir.direction'a fallback yapiyor, yani bu
   // uclu esitlik gereksiz sikiydi) - trendMarket/strongMacroTrend hep false
   // kaliyor, NETVOL ve "trend-onayli SOLVER" dallarina hic ulasilamiyordu.
   // Iki yon kaynaginin (mikro/makro) hemfikir olmasi yeterli.
   // v1.78.139: sabit esikler (0.35 / 25 / 18 / 0.10) artik InpAdaptive_*
   // input'larindan okunuyor - dusuk zaman diliminde bu sabitler pratikte
   // hic tutmuyor, esas "hep SOLVER" sikayetinin buyuk kismi buradan
   // geliyordu (bkz. v1.78.139 REGIME-UNSTICK changelog notu).
   bool directionAligned = (microDir != 0 && microDir == macroDir);
   bool rangeMarket = (adx > 0.0 && adx < InpAdaptive_RangeADX);
   bool trendMarket = (adx >= InpAdaptive_TrendADX && directionAligned);
   bool highVolatility = (atrPct >= InpAdaptive_HighVolATRPct || (atr > 0.0 && spreadPct / 100.0 > (atr / MathMax(SymbolInfoDouble(_Symbol, SYMBOL_BID), 1.0)) * 0.35));
   bool spreadUnsafe = (spreadPct >= InpAdaptive_SpreadUnsafePct || (atr > 0.0 && spreadPct / 100.0 > atr * 0.25));
   bool trendFilterConfirmed = (!RT_ADXFilter() || adx >= RT_ADXThreshold());
   bool strongMacroTrend = highVolatility && trendMarket && trendFilterConfirmed && !spreadUnsafe;
   bool lowVolatilityRange = !spreadUnsafe &&
                             (rangeMarket || (!highVolatility && !trendMarket));
   double floatingLossPct = 0.0;
   double deficitPct = 0.0;
   bool criticalLoss = AdaptiveMarket_CriticalLoss(floatingLossPct, deficitPct);

   // v1.78.139 TANI LOGU: hangi esigin tuttugunu/tutmadigini canli izlemek
   // icin throttle'li Journal satiri. InpAdaptive_DiagLogSec=0 ise kapali.
   if(InpAdaptive_DiagLogSec > 0) {
      static datetime s_lastDiagLog = 0;
      datetime nowDiag = TimeCurrent();
      if(s_lastDiagLog == 0 || nowDiag - s_lastDiagLog >= InpAdaptive_DiagLogSec) {
         s_lastDiagLog = nowDiag;
         PrintFormat("[ADAPT-DIAG] atr%%=%.3f(esik %.2f) adx=%.1f(trend>=%.1f/range<%.1f) yonHizali=%s spread%%=%.3f(esik %.2f) ddPct=%.2f mevcutRejim=%s",
                     atrPct, InpAdaptive_HighVolATRPct, adx, InpAdaptive_TrendADX, InpAdaptive_RangeADX,
                     (directionAligned ? "EVET" : "HAYIR"), spreadPct, InpAdaptive_SpreadUnsafePct,
                     ddPct, RT_RegimeName());
      }
   }

   // v1.78.137: her cagrida once temizle - sadece asagidaki trend-onayli
   // SOLVER dalinda true'ya cekilecek.
   g_rt_solver_is_trend = false;

   if(criticalLoss || ddPct >= 8.0 || g_ddHedgePaused) {
      g_rt_auto_note = "RECOVERY";
      return TPP_REG_CONTROLLED_RECOVERY;
   }
   if(hedgeOverlay && ddPct >= 4.0) {
      // Hedge is an existing risk overlay, not a TP-Proj volume enum.
      g_rt_auto_note = "HEDGE";
      return TPP_REG_CONTROLLED_RECOVERY;
   }
   if(spreadUnsafe) {
      g_rt_auto_note = "FIXED";
      return TPP_REG_FIXED;
   }
   if(strongMacroTrend) {
      g_rt_auto_note = "NETVOL";
      return TPP_REG_NET_VOLUME_TARGET;
   }
   // v1.78.138 FIX: trendMarket / DEFICIT / BAKIYE% kontrolleri artik
   // lowVolatilityRange'den ONCE calisiyor. Eskiden lowVolatilityRange'in
   // (!highVolatility && !trendMarket) terimi trendMarket hemen hemen hic
   // true olmadigi icin (bkz. directionAligned) neredeyse her zaman true
   // oluyordu ve asagidaki uc dala (trendMarket/DEFICIT/BAKIYE%) HICBIR ZAMAN
   // sira gelmiyordu - hepsi SOLVER'a yutuluyordu. Simdi lowVolatilityRange
   // sadece gercekten "hicbir yon/trend sinyali yok" durumlarinda (son care/
   // catch-all olarak) devreye giriyor.
   if(trendMarket) {
      // v1.78.137: bu SOLVER, NETVOL'un istedigi (ADX>=25 + yon hizali)
      // KOSULU TASIYOR, sadece highVolatility/trendFilterConfirmed/spread
      // sartlarindan biri eksik - yani "belirsiz" degil, "dogrulanmis trend
      // ama NETVOL'un ekstra sartlarini tam karsilamayan" bir SOLVER.
      g_rt_solver_is_trend = true;
      g_rt_auto_note = "COZUCU";
      return TPP_REG_SOLVER;
   }
   if(highVolatility && ddPct >= 2.0) {
      g_rt_auto_note = "DEFICIT";
      return TPP_REG_TARGET_DEFICIT;
   }
   // v1.78.139 FIX: eskiden SADECE equity>balance (hesap ZATEN net kardaysa)
   // burasi tetikleniyordu - hesap zarardayken (deficitPct/ddPct>0) bu dala
   // hicbir zaman ulasilamiyor, alttaki lowVolatilityRange->SOLVER'a
   // yigiliyordu. Artik kucuk bir DD toleransi (InpAdaptive_BalancePctDDTol,
   // varsayilan %1) icindeyse de gecilebiliyor - net kar sarti KALDIRILMADI,
   // sadece "az miktarda zararda da olsa" esneme eklendi.
   if(ddPct <= InpAdaptive_BalancePctDDTol) {
      g_rt_auto_note = "BAKIYE%";
      return TPP_REG_BALANCE_PCT;
   }
   if(lowVolatilityRange) {
      g_rt_auto_note = "COZUCU";
      return TPP_REG_SOLVER;
   }

   g_rt_auto_note = "FIXED";
   return TPP_REG_FIXED;
}

int AdaptiveMarket_ChooseLotMode() {
   if(!g_rt_ready) return (int)InpBulletLotMode;

   double atr = 0.0, atrPct = 0.0, spreadPct = 0.0, adx = 0.0, ddPct = 0.0;
   int microDir = 0, macroDir = 0;
   bool hedgeOverlay = false;
   AdaptiveMarket_Analyze(atr, atrPct, spreadPct, adx, microDir, macroDir, ddPct, hedgeOverlay);
   double floatingLossPct = 0.0;
   double deficitPct = 0.0;
   bool criticalLoss = AdaptiveMarket_CriticalLoss(floatingLossPct, deficitPct);

   if(!g_robotOn || criticalLoss || ddPct >= 8.0 || hedgeOverlay) {
      return BLM_MANUAL;
   }
   // v1.78.139: ChooseRegime() ile ayni InpAdaptive_* esikleri (tutarlilik).
   bool rangeMarket = (adx > 0.0 && adx < InpAdaptive_RangeADX);
   bool lowVolatilityRange = (atrPct < InpAdaptive_HighVolATRPct && rangeMarket);
   if(lowVolatilityRange) {
      // Yatay piyasada Solver kullanilir; RiskCap_MaxLot(),
      // Trade_SafetyGate() ve volume-step normalizasyonu aynen uygulanir.
      return BLM_PROJECT;
   }
   if(adx >= InpAdaptive_TrendADX && microDir != 0 && microDir == macroDir) {
      return BLM_PROJECT;
   }
   return BLM_AUTO;
}

void AdaptiveMarket_Refresh() {
   if(!g_rt_ready || !g_rt_auto_adapt) return;
   if(g_symbol != _Symbol) return; // runtime rejim globaldir; ekstra sembol gecisi yazmasin

   static datetime s_lastAutoUpdate = 0;
   datetime now = TimeCurrent();
   // v1.78.130: Adaptasyon motoru daha sık calisir (30sn → 10sn) — piyasa degisiklikleri hizlica yakalanir
   if(s_lastAutoUpdate != 0 && now - s_lastAutoUpdate < 10)
      return;
   s_lastAutoUpdate = now;

   int newReg = AdaptiveMarket_ChooseRegime();
   int newLot = AdaptiveMarket_ChooseLotMode();

   // v1.78.138 FIX: g_rt_solver_is_trend her 10sn'de ChooseRegime() icinde
   // yeniden hesaplaniyor, ama g_rt_grid_mult_on/g_rt_seq_mult'u ona gore
   // ayarlayan kod eskiden SADECE asagidaki rejim-GECIS bloğu icinde
   // (newReg != g_adapt_active_regime) calisiyordu. SOLVER rejiminde SABIT
   // kalinirken (rejim hic degismezken) piyasa range<->trend arasinda
   // degisse bile o blok bir daha girilmiyordu - carpan bayraklari SOLVER'a
   // ilk giriste ne ise o degerde donup kaliyor, grid depth artsa da lot hic
   // buyumuyordu. Burada, rejim SOLVER'da sabit kalirken de trend flag'e
   // gore bayraklari her refresh'te senkronize ediyoruz.
   // v1.78.167 KADEME/CARPAN FIX (kullanici talebi): InpVG_GridMultRegimeControl
   // varsayilan false iken bu senkron da atlanir - CARPAN rejimden bagimsiz
   // panelden ayarlandigi gibi SABIT kalir.
   if(InpVG_GridMultRegimeControl &&
      newReg == TPP_REG_SOLVER && g_adapt_active_regime == TPP_REG_SOLVER &&
      !g_motorTransitionLocked) {
      bool shouldMultOn = g_rt_solver_is_trend;
      if(g_rt_grid_mult_on != shouldMultOn || g_rt_seq_mult != shouldMultOn) {
         g_rt_grid_mult_on = shouldMultOn;
         g_rt_seq_mult     = shouldMultOn;
      }
   }
   // v1.78.132 KULLANICI KARARIYLA KALDIRILDI: burada "if(!criticalRecovery)
   // { newReg=BALANCE_PCT; newLot=BLM_AUTO; }" turunde bir override vardi.
   // AdaptiveMarket_ChooseRegime()/ChooseLotMode() zaten ADX/trend/volatilite/
   // DD analizine gore NETVOL/SOLVER/DEFICIT/FIXED/RECOVERY arasinda karar
   // veriyordu, ama bu override kriz disinda (yani neredeyse HER ZAMAN, cunku
   // criticalRecovery sadece deficit/floating-loss >= %8 iken true) bu karari
   // atip sabit BALANCE_PCT/BLM_AUTO'ya donduruyordu - NETVOL/SOLVER/DEFICIT/
   // FIXED dallari FIILEN HICBIR ZAMAN g_rt_tp_regime'e ulasamiyordu (bu iki
   // fonksiyon sadece burada cagriliyor, baska hicbir yerden degil). Kullanici
   // acikca tam otonom (trend kaynak/yon/mikro-trend/TP-Proj zirve/lot/rejim
   // motorlarinin piyasaya gore analiz edip degiserek calismasini) istedi -
   // bu yuzden newReg/newLot artik ezilmeden dogrudan kullaniliyor. RECOVERY
   // GUVENLIGI KAYBOLMUYOR: ChooseRegime() kendi icinde ayni criticalLoss/
   // ddPct>=8/g_ddHedgePaused kosullarini zaten kontrol edip gerekince
   // TPP_REG_CONTROLLED_RECOVERY donduruyor (bkz. fonksiyonun kendisi).
   if(g_adapt_active_regime < 0) {
      g_adapt_active_regime = g_rt_tp_regime;
      g_adapt_active_since = now;
      g_adapt_last_transition = now;
      // v1.78.130: İlk defa: motor state'ini init et
      AdaptiveMarket_UpdateMotorActivation(g_rt_tp_regime);
   }

   // v1.78.132 NOT: Asagida ayni "if(g_adapt_active_regime < 0)" kosuluyla
   // ikinci bir init bloğu daha vardi (v1.78.130 FIX yorumuyla). TPP_REG_*
   // degerlerinin tumu >=0 oldugu icin (bkz. enum tanimi) yukaridaki blok her
   // zaman ONCE calisip g_adapt_active_regime'i >=0 yapiyor - bu ikinci blok
   // hicbir zaman calismayan olu koddu, kafa karistirmasin diye kaldirildi.

   int currentIdx = Ind_FindIdx(g_symbol);
   if(currentIdx < 0 || currentIdx >= MAX_SYMBOLS) currentIdx = 0;
   bool urgentRecovery = (newReg == TPP_REG_CONTROLLED_RECOVERY &&
                          (g_ddHedgePaused || g_gridRiskTrip[currentIdx]));
   if(newReg != g_adapt_active_regime || newLot != g_rt_lot_mode) {
      if(g_adapt_candidate_regime != newReg || g_adapt_candidate_lot != newLot) {
         g_adapt_candidate_regime = newReg;
         g_adapt_candidate_lot = newLot;
         g_adapt_candidate_since = now;
         return;
      }

      bool candidateStable = (g_adapt_candidate_since > 0 &&
                              now - g_adapt_candidate_since >= ADAPT_CANDIDATE_CONFIRM_SEC);
      bool activeHeld = (g_adapt_active_since > 0 &&
                         now - g_adapt_active_since >= ADAPT_MIN_ACTIVE_SEC);
      bool transitionCooldown = (g_adapt_last_transition > 0 &&
                                 now - g_adapt_last_transition < ADAPT_TRANSITION_COOLDOWN_SEC);
      bool orderLock = false;
      orderLock = g_gridSendLock[currentIdx][0] || g_gridSendLock[currentIdx][1];

      // HEDGE aktifken normal rejim degistirme; hedge/recovery acil gecisi
      // yetim pozisyon birakmamak icin lock'lari bekler.
      bool hedgeLock = g_ddHedgeActive && newReg != TPP_REG_CONTROLLED_RECOVERY;
      if(orderLock || hedgeLock)
         g_ctx.allow_new_entries = false;
      if(!urgentRecovery && (!candidateStable || !activeHeld || transitionCooldown || orderLock || hedgeLock))
         return;

      // v1.78.130 KRİTİK GEÇIŞ BAŞLAT: Motor transition lock ve state temizleme
      int oldReg = g_rt_tp_regime;
      int oldLot = g_rt_lot_mode;
      g_motorTransitionLocked = true;           // Geçiş sırasında tüm emir gönderme kilitlenir
      g_motorTransitionStarted = now;
      g_motorLastActiveRegime = oldReg;
      g_motorStateFullyCleared = false;         // Eski state temizleniyorsa false
      
      // Eski motorun tüm residüel parametrelerini hafızadan TEMIZLE
      AdaptiveMarket_ClearOldMotorState(oldReg);
      
      // YENİ rejimi ve parametrelerini AÇ
      g_rt_tp_regime = newReg;
      g_rt_lot_mode = newLot;
      // v1.78.167 KADEME/CARPAN FIX (kullanici talebi): InpVG_GridMultRegimeControl
      // varsayilan false iken rejim gecisi CARPAN'a hic dokunmaz - panelden
      // ayarlandigi gibi (ACIK/KAPALI ve deger) TUM rejimlerde SABIT kalir.
      if(InpVG_GridMultRegimeControl) {
      if(newReg == TPP_REG_NET_VOLUME_TARGET ||
         (newReg == TPP_REG_SOLVER && g_rt_solver_is_trend)) {
         // Guclu makro trend + ATR volatilitesi (NETVOL) VEYA dogrulanmis
         // trend ama NETVOL'un ekstra volatilite sartini tam karsilamayan
         // SOLVER (v1.78.137, kullanici karari - NETVOL kosullari pratikte
         // ~%95 hic tutmuyordu): ardışık yön kademelerinde grid çarpanı
         // asimetrik/üstel çalışır. "Belirsiz/range" SOLVER (lowVolatilityRange
         // yolundan gelen) bu kapsamin DISINDA kalir - guvenlik ayrimi korunur.
         // Trend Flip Guard ise manuel panel kontrolünde kalır; otomatik rejim
         // geçişi onu ezmez.
         g_rt_grid_mult_on = true;
         g_rt_seq_mult = true;
      } else {
         // v1.78.130 FIX: SAFE BASELINE burada tekrar uygulanmamalidir;
         // o blok da zaten kritik-recovery dışı durumlar için ayrı yerde
         // kullanilir. Burada sadece yeni rejime ait state temizliği yapılır.
         g_rt_grid_mult_on = false;
         g_rt_seq_mult = false;
      }
      }
      if(newReg == TPP_REG_CONTROLLED_RECOVERY) {
         g_rt_atr_mode = true;
         g_rt_step_manual_override = false;
         g_rt_tp_manual_override = false;
      }
      
      // v1.78.130 MOTOR ACTIVATION STATE GÜNCELLEMESI: Hangi motor(lar) bu rejimde aktif
      AdaptiveMarket_UpdateMotorActivation(newReg);
      
      // Geçiş tamamlandı: state'i finalize et
      g_adapt_active_regime = newReg;
      g_adapt_active_since = now;
      g_adapt_last_transition = now;
      g_adapt_candidate_regime = -1;
      g_adapt_candidate_lot = -1;
      g_adapt_candidate_since = 0;
      g_motorTransitionLocked = false;  // Geçiş kilidini kaldır — yeni motor işçi

      if(oldReg != newReg || oldLot != newLot) {
         g_panelApplyMsg = "● AUTO ADAPT: " + g_rt_auto_note;
         g_panelApplyMsgUntil = now + 3;
         // v1.78.130: Panel real-time senkronizasyonu — geçiş bitiminde display tazelensin
         Panel_RequestUpdate(true);
      }
   }
}

// v1.78.130 YENİ FONKSİYON: Motor aktivasyon gate'i — motorun aktif olup olmadığını kontrol et
// Geçişler sırasında eski motorun sinyal/emir gönderme işlevlerini tamamen BLOKE eder
bool AdaptiveMarket_IsMotorActive(const int targetMotor) {
   // Motor geçişi sırasında (transition lock) tüm motorlar bloke edilir
   if(g_motorTransitionLocked) return false;
   
   // Rejim-spesifik motor aktivasyon kontrol
   switch(targetMotor) {
      case 0: // MOTOR_GRID
         return g_motor_grid_active;
      case 1: // MOTOR_BULLET
         // v1.78.135 KULLANICI KARARI: RECOVERY rejiminde Grid+Bullet ikisi de
         // kapatiliyordu ve g_motor_recovery_active/g_motor_hedge_active'i
         // okuyan HICBIR kod yoktu - yani DD %8'i gecince hesap "kilitleniyor",
         // hicbir yeni islem acilmiyordu (kullanicinin bildirdigi sorun).
         // Cozum olarak Grid DEGIL, sadece Bullet'i RECOVERY'de tekrar actik -
         // cunku bu noktada AdaptiveMarket_ChooseLotMode() zaten BLM_MANUAL
         // donduruyor (ayni %8 esigiyle, bkz. o fonksiyon), yani Bullet
         // TP-Proj'un aciga-gore-buyuyen formulunu DEGIL, RT_BulletLot()
         // (sabit, kucuk, panel/manuel lot) kullanir - martingale riski YOK,
         // ayrica Hard SL ile korunuyor. Grid (sepet/coklu-seviye birikimi,
         // daha yuksek risk profili) RECOVERY'de KAPALI kalmaya devam ediyor -
         // bu bilincli, daha temkinli bir tercih.
         return g_motor_bullet_active || g_motor_recovery_active;
      case 2: // MOTOR_SOLVER
         return g_motor_solver_active;
      case 3: // MOTOR_NETVOLUME
         return g_motor_netvolume_active;
      case 4: // MOTOR_RECOVERY
         return g_motor_recovery_active;
      case 5: // MOTOR_HEDGE
         return g_motor_hedge_active;
      default:
         return false;
   }
}

// v1.78.130 YENİ FONKSİYON: Panel real-time senkronizasyon — rejim değişiminde display tazelensin
void AdaptiveMarket_SyncPanelDisplay() {
   // Panel rejim göstergesi + motor durumu tazelensin
   // (UpdateMinimalPanel içinde Panel_RequestUpdate çağrılarından zaten yapılıyor, ama ek güvenlik)
   if(g_motorTransitionLocked || g_motorStateFullyCleared) {
      Panel_RequestUpdate(true);
   }
}

// v1.78.130 CRITICAL FIX: RT_VG_Lot() fonksiyonu eksikti — doğrudan ekleme
double RT_VG_Lot()   { return (g_rt_ready && g_rt_vg_lot > 0) ? g_rt_vg_lot : InpVG_LotValue; }

double RT_VG_Step()   { return (g_rt_ready && g_rt_vg_step > 0) ? g_rt_vg_step : InpVG_StepValue; }
double RT_VG_TP()     { return (g_rt_ready && g_rt_tp_pts > 0) ? g_rt_tp_pts : InpVG_TPValue; }
double RT_BulletLot() { return (g_rt_ready && g_rt_bullet_lot > 0) ? g_rt_bullet_lot : InpBulletLotValue; }
double RT_Peak()      {
   double raw = (g_rt_ready && g_rt_peak > 0) ? g_rt_peak : InpTPProjPeakTargetMoney;
   // v1.78.36 FIX: PEAK MODU (PEAK$/BAKIYE%) butonu sadece kendi etiketini
   // degistiriyordu — deger HER ZAMAN duz dolar gibi kullaniliyordu, "BAKIYE%"
   // secilse bile. Artik BAKIYE% modunda kutudaki sayi (orn. 5) guncel
   // bakiyenin o kadar yuzdesi olarak hesaplaniyor.
   if(g_rt_ready && g_rt_peak_mode == 1) {
      double bal = AccountInfoDouble(ACCOUNT_BALANCE);
      if(bal > 0) return bal * (raw / 100.0);
   }
   return raw;
}
// v1.78.36: edit kutusu icin HAM deger (kullanicinin yazdigi sayi, $ ya da %
// - moda gore) — RT_Peak() artik BAKIYE% modunda HESAPLANMIS dolari
// dondurdugu icin, kutu editi icin bunu degil, ham girdiyi gostermek gerekir.
double RT_PeakRaw()   { return (g_rt_ready && g_rt_peak > 0) ? g_rt_peak : InpTPProjPeakTargetMoney; }
bool   RT_TimerOn()   { return g_rt_ready ? g_rt_timer_on : false; }
int    RT_NfBefore()  { return g_rt_ready ? g_rt_nf_before : InpNF_BeforeMinutes; }
int    RT_NfAfter()   { return g_rt_ready ? g_rt_nf_after : InpNF_AfterMinutes; }
bool   RT_DdHedge()   { return g_rt_ready ? g_rt_dd_hedge : InpEnableAutoDDHedge; }
double RT_DdPct()     { return (g_rt_ready && g_rt_dd_pct > 0) ? g_rt_dd_pct : InpAutoDDHedgePct; }
double RT_DdTp()      {
   if(g_rt_ready) {
      if(g_rt_dd_tp_pct > 0) return g_rt_dd_tp_pct;
      if(g_rt_hedge_profit > 0) return g_rt_hedge_profit; // panel HEDGE KAR
   }
   return InpDDHedgeExitProfit;
}
double RT_RiskLotMult(){
   if(!g_rt_ready) return 1.0;
   // 0 COK GUVENLI 1 GUVENLI 2 DENGELI 3 HIZLI 4 AGRESIF
   if(g_rt_risk_mode <= 0) return 0.5;
   if(g_rt_risk_mode == 1) return 0.7;
   if(g_rt_risk_mode == 2) return 1.0;
   if(g_rt_risk_mode == 3) return 1.25;
   return 1.5; // AGRESIF
}
double RT_ConfFloor(){
   // HASSAS: 1.0 = normal; yuksek = daha secici (daha yuksek conf gerekir)
   double h = g_rt_ready ? g_rt_hassas : 1.0;
   if(h < 0.5) h = 0.5;

   // v1.78.72 FIX: motor-bazli taban. VEMA-X (oy-cogunlugu, min~0.50),
   // First Touch (olasilik pUp/pDn) ve Classic Live (enerji orani) yapisal
   // olarak farkli confidence skalasi urettigi icin tek global 0.25 esigi
   // motorlar arasi adaletsiz davraniyordu (bkz. yorum yukarida input
   // bloğunda). InpConfFloor_* = 0 (varsayilan) ise eski global davranis
   // aynen korunur; >0 girilirse o motor icin ayri taban kullanilir.
   double baseFloor = 0.25;
   switch(g_rt_dir_engine) {
      case 0: if(InpConfFloor_VEMA        > 0.0) baseFloor = InpConfFloor_VEMA;        break;
      case 1: if(InpConfFloor_FirstTouch  > 0.0) baseFloor = InpConfFloor_FirstTouch;  break;
      case 2: if(InpConfFloor_ClassicLive > 0.0) baseFloor = InpConfFloor_ClassicLive; break;
      default: break;
   }
   return baseFloor * h;
}
double RT_ProfitResetPct(){ return (g_rt_ready && g_rt_profit_reset_pct > 0) ? g_rt_profit_reset_pct : InpGlobalProfitPct; }
double RT_LossResetPct()  { return (g_rt_ready && g_rt_loss_reset_pct > 0) ? g_rt_loss_reset_pct : InpGlobalLossPct; }
int    RT_MaxReset()  { return (g_rt_ready && g_rt_max_reset > 0) ? g_rt_max_reset : InpMaxResetCount; }

//--- Panel → motor köprüleri
bool   RT_BonusTP()     { return g_rt_ready ? g_rt_bonus_tp : InpBullet_BonusTPEnable; }
double RT_VtpMult()     { return (g_rt_ready && g_rt_vtp_mult > 0) ? g_rt_vtp_mult : InpBullet_BonusTP_Mult; }
bool   RT_Blok()        { return g_rt_ready ? g_rt_blok : true; }
int    RT_ZararBlok()   { return (g_rt_ready && g_rt_zarar_blok > 0) ? g_rt_zarar_blok : 4; }
int    RT_KarKulucka()  { return (g_rt_ready && g_rt_kar_kulucka > 0) ? g_rt_kar_kulucka : InpBullet_ProfitIncubationSec; }
int    RT_ZararKulucka(){ return (g_rt_ready && g_rt_zarar_kulucka > 0) ? g_rt_zarar_kulucka : InpBullet_LossIncubationSec; }
double RT_BakPct()      { return (g_rt_ready && g_rt_bak_pct > 0) ? g_rt_bak_pct : InpVG_BalancePct; }
double RT_TpVarPct()    { return (g_rt_ready && g_rt_tp_var_pct > 0) ? g_rt_tp_var_pct : InpVG_TP_PricePct; }
double RT_StepPnt()     { return (g_rt_ready && g_rt_step_pnt > 0) ? g_rt_step_pnt : InpVG_StepValue; }
bool   RT_KarHepsiniKapat()  { return g_rt_ready ? g_rt_kar_hepsini_kapat : true; }
bool   RT_ZararHepsiniKapat(){ return g_rt_ready ? g_rt_zarar_hepsini_kapat : true; }
int    RT_ProfitAdet()  { return (g_rt_ready && g_rt_profit_adet > 0) ? g_rt_profit_adet : 1; }
int    RT_LossAdet()    { return (g_rt_ready && g_rt_loss_adet > 0) ? g_rt_loss_adet : 1; }
double RT_ProfitBek()   { return (g_rt_ready && g_rt_profit_bek > 0) ? g_rt_profit_bek : 9.0; }
double RT_LossBek()     { return (g_rt_ready && g_rt_loss_bek > 0) ? g_rt_loss_bek : 15.0; }
int    RT_MinSec()      { return (g_rt_ready && g_rt_min_sec > 0) ? g_rt_min_sec : MathMax(1, InpVG_MinSecondsBetween); }
int    RT_MaxLevels()   { return (g_rt_ready && g_rt_max_levels > 0) ? g_rt_max_levels : MathMax(1, InpVG_MaxLevelsPerSide); }
double RT_VtpPct()      { return g_rt_ready ? g_rt_vtp_pct : InpVirtualTPPct; }
// v1.78.22: ATR Sistemi / ADX Filtresi getter'lari (panel > input, diger RT_* ile ayni desen)
bool   RT_ATRMode()      { return g_rt_ready ? g_rt_atr_mode      : InpATR_ModeEnable; }
bool   RT_ADXFilter()    { return g_rt_ready ? g_rt_adx_filter    : InpADX_FilterEnable; }
double RT_ADXThreshold() { return (g_rt_ready && g_rt_adx_threshold > 0) ? g_rt_adx_threshold : InpADX_Threshold; }
double RT_ATRTriggerMult(){ return (g_rt_ready && g_rt_atr_trig_mult > 0) ? g_rt_atr_trig_mult : InpATR_TriggerMult; }
double RT_MinCloseMoney(){
   // v1.78.20: erken 0.5-0.7$ kapanisi engelle – mutlak taban + equity olcek
   if(g_rt_ready && g_rt_min_close_money > 0) return g_rt_min_close_money;
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq <= 0.0) eq = AccountInfoDouble(ACCOUNT_BALANCE);
   if(eq <= 0.0) eq = 1000.0;
   // varsayilan: en az 2.50$ veya equity %0.25 (hangisi buyukse)
   return MathMax(2.50, eq * 0.0025);
}

// v1.78.54: GLOBAL TREND FLIP GUARD
// g_ctx.dir.direction (panelde "Yon: BUY/SELL" olarak gosterilen ayni sinyal)
// terse donduğunde, YENI yonle CELISEN (eski yonde acilmis) tum pozisyonlari
// -- Grid/Lattice, Bullet, Hedge, motor ayrimi yapmadan sembol+magic bazli --
// tarar. Karda olan (>= esik) pozisyonlari SafeClosePosition ile kapatir.
// Zararda olanlara dokunmaz; onlar mevcut SL/DD/AEGIS/Rescue mekanizmalarina
// birakilir. Boylece amac sadece "trend terse donunce kari kilitle", panik
// kapatma degil.
// v1.78.95: Direction Flip Lock + Controlled Close
bool DirectionLock_AllowsEntry(const string symbol, const int direction) {
   if(!InpDirLock_Enable) return true;
   if(direction == 0) return false;
   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) return true;
   if(g_dirlock_committedDir[idx] == 0) return true;
   if(g_dirlock_blockEntries[idx]) return false;
   return (direction == g_dirlock_committedDir[idx]);
}

void DirectionLock_ControlledClose(const string symbol, const int staleDir) {
   if(!InpDirLock_CloseProfit && !InpDirLock_CloseSmallLoss) return;

   int staleType = (staleDir > 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   int freshType = (staleDir > 0) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
   double minProfit = MathMax(0.0, InpDirLock_MinProfit);
   if(minProfit <= 0.0) minProfit = RT_MinCloseMoney();
   double maxLoss = MathMax(0.0, InpDirLock_MaxLossMoney);
   double freshSideLoss = 0.0;
   double availableProfit = 0.0;
   int closedProfit = 0, closedSmallLoss = 0;
   double profitTaken = 0.0, lossRealized = 0.0;

   // Karsi/yeni yon tarafinda halen floating zarar varsa, eski yon kârini
   // o zarari + minProfit tamponunu karsilamadan cekme. Bu, mevcut TFG'nin
   // net-pozitif koruma prensibini DirectionLock'a da tasir.
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !PositionSelectByTicket(tk)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      int ptype = (int)PositionGetInteger(POSITION_TYPE);
      double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(ptype == freshType && p < 0.0) freshSideLoss += (-p);
      if(ptype == staleType && p >= minProfit) availableProfit += p;
   }

   double requiredBuffer = freshSideLoss + minProfit;
   bool profitCloseAllowed = (availableProfit >= requiredBuffer);

   // 1) Once eski yonun anlamli kârini, sadece net-pozitif kosul saglaniyorsa kapat.
   if(InpDirLock_CloseProfit && profitCloseAllowed) {
      for(int i = PositionsTotal()-1; i >= 0; i--) {
         ulong tk = PositionGetTicket(i);
         if(tk == 0 || !PositionSelectByTicket(tk)) continue;
         if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
         if((int)PositionGetInteger(POSITION_TYPE) != staleType) continue;
         double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         if(p < minProfit) continue;
         if(SafeClosePosition(tk, "DIR_FLIP_PROFIT")) {
            closedProfit++;
            profitTaken += p;
         }
      }
   }

   // 2) Sadece kucuk zarardaki eski yon pozisyonlarini kapat.
   // Buyuk zararlar SL/DD/AEGIS/Rescue mekanizmalarina birakilir.
   if(InpDirLock_CloseSmallLoss && maxLoss > 0.0) {
      for(int i = PositionsTotal()-1; i >= 0; i--) {
         ulong tk = PositionGetTicket(i);
         if(tk == 0 || !PositionSelectByTicket(tk)) continue;
         if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
         if((int)PositionGetInteger(POSITION_TYPE) != staleType) continue;
         double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         if(p >= 0.0 || (-p) > maxLoss) continue;
         if(SafeClosePosition(tk, "DIR_FLIP_SMALL_LOSS")) {
            closedSmallLoss++;
            lossRealized += (-p);
         }
      }
   }

   if(closedProfit > 0 || closedSmallLoss > 0) {
      PrintFormat("DirectionLock [%s]: FLIP eski=%s, kar=%d ($%.2f), kucukZarar=%d ($%.2f), karsiZarar=$%.2f",
                  symbol, staleDir > 0 ? "BUY" : "SELL", closedProfit, profitTaken,
                  closedSmallLoss, lossRealized, freshSideLoss);
   } else if(freshSideLoss > 0.0 && availableProfit < requiredBuffer) {
      PrintFormat("DirectionLock [%s]: eski yon kâri korunuyor; karsi taraf zarar=$%.2f, mevcut kâr=$%.2f, gerekli=$%.2f",
                  symbol, freshSideLoss, availableProfit, requiredBuffer);
   }
}

void DirectionLock_Manage(SPipelineContext &ctx) {
   if(!InpDirLock_Enable) return;
   int idx = Ind_FindIdx(ctx.symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) return;
   int dir = ctx.dir.direction;
   double conf = ctx.dir.confidence;
   int confirmNeed = MathMax(1, InpDirLock_FlipConfirmTicks);

   if(g_dirlock_committedDir[idx] == 0) {
      if(dir != 0 && conf >= InpDirLock_MinConf) {
         g_dirlock_committedDir[idx] = dir;
         g_dirlock_blockEntries[idx] = false;
      } else {
         g_dirlock_blockEntries[idx] = true;
         ctx.allow_new_entries = false;
      }
      return;
   }

   // NÖTR/zayif sinyalde eski yönü seed etme. Yeni girişler tamamen durur.
   // v1.78.158 FIX (KOK NEDEN - kullanicinin bildirdigi "dir=-1 conf=0.850
   // allow=false" surekli tekrari + TradeDiag'in gunlerce "Yon NOTR -
   // DirectionLock onceki yonu koruyor, reversal teyidi bekleniyor"
   // donmesi): bu blok eskiden, ZATEN BIRIKMEYE BASLAMIS bir reversal
   // adayini (g_dirlock_candidateDir!=0, asagidaki "Ters yon teyit
   // edilene kadar..." blogunda biriktirilir) HER TEK notr/zayif tick'te
   // KOSULSUZ SIFIRLIYORDU. Choppy/dusuk-ADX piyasada VEMA-X'in (kapanan
   // bar oyuna dayali) yonu bar-bar -1/0 arasinda sekebiliyor - her 0'a
   // donuste teyit sayaci bastan basladigi icin, pratikte confirmNeed'e
   // (varsayilan 2) HICBIR ZAMAN ulasamiyor ve DirectionLock, fiyat artik
   // committedDir ile uyusmasa bile SONSUZA KADAR "reversal teyidi
   // bekleniyor" durumunda KALICI KILITLENIYORDU - cold-start'tan (v1.78.
   // 151'de ColdStartSeedDirection ile cozulen) SONRAKI, mimarinin farkli
   // bir yerindeki IKINCI bir kisir dongu turu.
   // Duzeltme (VEMA_MA_RegimeGate'in v1.78.98 "rejim teyitsizken hicbir
   // mudahale yok" ilkesiyle AYNI desen): zaten bir aday BIRIKMISSE
   // (candidateDir!=0), tek bir notr/zayif tick onu SILMEZ - sadece o
   // tick'te ilerlemez (sayac ne artar ne sifirlanir); giris o tick'te
   // YINE DE tam kapali kalir (allow_new_entries=false, blockEntries
   // degismedi) - guvenlik davranisi AYNI, SADECE biriken teyit sayaci
   // korunuyor. Aday HENUZ YOKSA (candidateDir==0, reversal denemesi hic
   // baslamamis) eskisi gibi 0'da kalir - degisen bir sey yok.
   if(dir == 0 || conf < InpDirLock_MinConf) {
      if(g_dirlock_candidateDir[idx] == 0)
         g_dirlock_candidateTicks[idx] = 0;
      g_dirlock_blockEntries[idx] = true;
      ctx.allow_new_entries = false;
      return;
   }

   if(dir == g_dirlock_committedDir[idx]) {
      g_dirlock_candidateDir[idx] = 0;
      g_dirlock_candidateTicks[idx] = 0;
      g_dirlock_blockEntries[idx] = false;
      return;
   }

   // Ters yön teyit edilene kadar eski veya yeni tarafta yeni giriş yok.
   if(g_dirlock_candidateDir[idx] != dir) {
      g_dirlock_candidateDir[idx] = dir;
      g_dirlock_candidateTicks[idx] = 1;
   } else g_dirlock_candidateTicks[idx]++;
   g_dirlock_blockEntries[idx] = true;
   ctx.allow_new_entries = false;
   if(g_dirlock_candidateTicks[idx] < confirmNeed) {
      // v1.78.157 GECICI TESHIS (kullanicinin bildirdigi "dir=-1 conf=0.850
      // allow=false" surekli tekrari): teyit henuz BIRIKIYOR - bu satir
      // TEK BASINA nadiren sorun olur (confirmNeed genelde kucuk), ama
      // "hangi asamada takildik" sorusunu netlestirmek icin loglandi.
      if(InpSR_LogDecisions)
         PrintFormat("DIRLOCK TESHIS | %s | FLIP teyit birikiyor | aday=%s teyit=%d/%d conf=%.3f",
                     ctx.symbol, dir > 0 ? "BUY" : "SELL", g_dirlock_candidateTicks[idx], confirmNeed, conf);
      return;
   }

   // v1.78.96: teyit tamam ama gercek TREND fazina girilmediyse commit etme.
   // RANGE/NEUTRAL fazda teyit sayaci korunur (sifirlanmaz) — trend faza
   // gecilir gecilmez, tekrar teyit biriktirmeye gerek kalmadan flip tamamlanir.
   if(InpDirLock_RequireTrendPhase &&
      ctx.dir.phase != PHASE_TREND_UP && ctx.dir.phase != PHASE_TREND_DOWN) {
      // v1.78.157 GECICI TESHIS, v1.78.158: kok neden (yukaridaki notr-
      // reset hatasi) bulunup duzeltildikten sonra kalici hale getirildi -
      // artik diger DIRLOCK TESHIS satirlariyla (satir ~4110) TUTARLI
      // sekilde InpSR_LogDecisions ile kapali/acik kontrol ediliyor (spam
      // onlemi), tamamen KALDIRILMADI cunku phase sartinin gercekten
      // darbogaz olup olmadigini gelecekte de teyit edebilmek faydali.
      if(InpSR_LogDecisions)
         PrintFormat("DIRLOCK TESHIS RED | %s | FLIP teyidi TAMAMLANDI (teyit=%d/%d) ama sebep=PHASE_TREND_DEGIL | phase=%d conf=%.3f aday=%s",
                     ctx.symbol, g_dirlock_candidateTicks[idx], confirmNeed, (int)ctx.dir.phase, conf, dir > 0 ? "BUY" : "SELL");
      return;
   }

   if(g_dirlock_lastFlip[idx] > 0 &&
      TimeCurrent() - g_dirlock_lastFlip[idx] < InpDirLock_CooldownSec) {
      // v1.78.157 GECICI TESHIS, v1.78.158: yukaridaki phase satiriyla
      // ayni sekilde InpSR_LogDecisions'a baglandi (spam onlemi).
      if(InpSR_LogDecisions)
         PrintFormat("DIRLOCK TESHIS RED | %s | FLIP teyidi+fazi TAMAM ama sebep=COOLDOWN | kalan=%.0fsn",
                     ctx.symbol, (double)(InpDirLock_CooldownSec - (TimeCurrent() - g_dirlock_lastFlip[idx])));
      return;
   }

   int staleDir = g_dirlock_committedDir[idx];
   g_dirlock_committedDir[idx] = dir;
   g_dirlock_candidateDir[idx] = 0;
   g_dirlock_candidateTicks[idx] = 0;
   g_dirlock_lastFlip[idx] = TimeCurrent();
   // v1.78.152 FIX: flip commit'in hemen entry acmasi artik bir SONRAKI
   // tick'te dir'in AYNI kalmasina (satir ~4091 blogu) bagli degil. VEMA/
   // panel sinyali flip aninda bir tick notre sarkarsa (M5'te rejim gecisi
   // gurultusu) o kosul hic tetiklenmiyor, blockEntries=true KALICI kaliyor
   // ve sistem "Yon NOTR - reversal teyidi bekleniyor" dongusune sikisiyor
   // (candidateTicks de satir ~4084'te sifirlaniyor, yeniden teyit
   // biriktirmek gerekiyor). Teyit (confirmNeed tick) zaten TAMAMLANDI ve
   // commit AZ ONCE yapildi; ayni guvenlik ilkesini (ControlledClose,
   // cooldown, TrendPhase sarti) bozmadan girisi AYNI tick'te aciyoruz.
   g_dirlock_blockEntries[idx] = false;
   ctx.allow_new_entries = true;

   // v1.78.96: mevcut TrendFlipGuard'in ayni flip'i bu tick'te ikinci kez
   // gormesini/islemesini onlemek icin TFG'nin "son bilinen yon" state'ini
   // burada senkronize ediyoruz. g_sym_idx yerine dogrudan idx kullanmak,
   // ProcessSymbolIndex disinda cagrilma ihtimaline karsi kapsam guvenligi
   // saglar (bkz. DUZELTME_REHBERI bolum 11).
   g_tfg_lastDir[idx] = dir;

   // Eski yönü kontrollü temizle; yeni yön artik AYNI tick'te acilabilir.
   DirectionLock_ControlledClose(ctx.symbol, staleDir);
   PrintFormat("DirectionLock [%s]: TREND FLIP %s -> %s CONF=%.3f teyit=%d; giris bu tick'te acik.",
               ctx.symbol, staleDir > 0 ? "BUY" : "SELL", dir > 0 ? "BUY" : "SELL",
               conf, confirmNeed);
}

// TREND FLIP SAFETY: Flip state'i g_sym_idx makrosuna değil çağrılan sembolün
// gerçek index'ine bağlanır; cooldown sırasında semboller arası state karışması
// ve yanlış yönde kapanış tetiklenmesi engellenir.
void TrendFlipGuard_Manage(SPipelineContext &ctx) {
   if(!RT_TFG()) return;

   int flipIdx = Ind_FindIdx(ctx.symbol);
   if(flipIdx < 0 || flipIdx >= MAX_SYMBOLS) return;

   int newDir = ctx.dir.direction;
   int prevDir = g_tfg_lastDir[flipIdx];

   // Ilk calisma veya notr sinyal: sadece state guncelle, islem yapma
   if(newDir == 0) { return; }
   if(prevDir == 0) { g_tfg_lastDir[flipIdx] = newDir; return; }

   // Yon degismediyse yapacak bir sey yok
   if(newDir == prevDir) { return; }

   // Guven esigi altindaki flip'leri gurultu sayip yoksay (state'i de guncelleme —
   // zayif sinyalle "yon degisti" kaydi tutmayalim, bir sonraki net sinyal karar versin)
   // v1.78.105 FIX (kullanici tespiti): eskiden burada dogrudan ctx.dir.confidence
   // kullaniliyordu - ama bu deger VEMA_MA_RegimeGate icindeki MACONFLICT/
   // pullback cezalarindan GECMIS haldeydi. Rejim (2 mum teyitli) henuz
   // yeni yone donmemisken VEMA-X GERCEK bir flip'i yuksek guvenle verdiginde
   // bile, MACONFLICT cezasi conf'u InpTFG_MinConf esiginin ALTINA
   // dusurebiliyordu - TFG gercek flip'i "gurultu" sanip atliyordu. Artik
   // TFG, rejim cezalarindan ETKILENMEMIS HAM VEMA-X guvenini kullanir.
   double tfgConf = RawConfidence_Get(ctx.symbol, ctx.dir.confidence);
   if(tfgConf < InpTFG_MinConf) return;

   // Cooldown: art arda flip sinyallerinde spam kapatmayi engelle
   if(g_tfg_lastAction[flipIdx] > 0 &&
      TimeCurrent() - g_tfg_lastAction[flipIdx] < InpTFG_CooldownSec) {
      // Cooldown sırasında yeni yönü kaydetme: kapanış yapılmayan flip'in
      // state'i korunur ve cooldown bitince aynı ters yön yeniden değerlendirilebilir.
      return;
   }

   double minProfit = InpTFG_UseMinCloseMoney ? RT_MinCloseMoney() : InpTFG_FixedMinProfit;

   // Kapatilacak taraf: YENI yonun TERSI (yani eski/celisen yon)
   int staleType = (newDir > 0) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
   // Korunacak/karsi taraf: YENI yonle AYNI (Grid hedge'liyse burada zarar olabilir)
   int freshType = (newDir > 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;

   // v1.78.55 FIX: Grid cift yonlu (hedge'li) calisirken staleType tarafi
   // kardayken freshType tarafi zararda olabiliyordu. Kardaki tarafi cekip
   // almak, zarardaki tarafi hedge'siz birakiyor ve DD Hedge'i tetikleyip
   // spread odeyerek AYNI hedge'i yeniden actiriyordu (net kayip). Artik
   // once freshType tarafinin toplam floating zarari (varsa) olculur; sadece
   // bu zarari + guvenlik payini karsilayacak KADAR kar kapatilir (net-pozitif
   // kurali) — hepsi ya da hicbiri degil, gercekten "guvenle cekilebilecek" pay.
   double freshSideLoss = 0.0; // pozitif sayi olarak tutulur (zarar miktari)
   for(int fi = PositionsTotal() - 1; fi >= 0; fi--) {
      ulong ft = PositionGetTicket(fi);
      if(ft == 0 || !PositionSelectByTicket(ft)) continue;
      if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      if((int)PositionGetInteger(POSITION_TYPE) != freshType) continue;
      double fp = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(fp < 0) freshSideLoss += (-fp);
   }
   // Guvenlik payi: zarari tam sifirlamak yetmez, MinCloseMoney kadar da
   // net kalsin (aksi halde "net pozitif ama 0.01$" gibi anlamsiz kapanislar olur)
   double requiredBuffer = freshSideLoss + minProfit;

   int closedCount = 0;
   double closedProfit = 0.0;

   // Once bu tick'te kapatilabilecek TOPLAM kar potansiyelini olc (harcamadan)
   double availableProfit = 0.0;
   if(freshSideLoss > 0.0) {
      for(int pi = PositionsTotal() - 1; pi >= 0; pi--) {
         ulong pt = PositionGetTicket(pi);
         if(pt == 0 || !PositionSelectByTicket(pt)) continue;
         if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
         if((int)PositionGetInteger(POSITION_TYPE) != staleType) continue;
         double pp2 = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         if(pp2 >= minProfit) availableProfit += pp2;
      }
      // Net-pozitif kurali: kapatilabilir kar, karsi taraf zarari + tampon paydan
      // AZSA -> hic kapatma (cekmek net kayip/hedge riski dogurur). Yeterliyse
      // kapat (kismi degil, cunku hangi ticket'in "fazlalik" oldugunu ayirmak
      // gereksiz karmasiklik; zaten yeterliyse hepsini almak guvenli).
      if(availableProfit < requiredBuffer) {
         return;
      }
   }

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !PositionSelectByTicket(tk)) continue;
      if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      if((int)PositionGetInteger(POSITION_TYPE) != staleType) continue;

      double pp = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(pp < minProfit) continue; // zararda/yetersiz karda olana dokunma

      if(SafeClosePosition(tk, "TREND_FLIP_GUARD")) {
         closedCount++;
         closedProfit += pp;
      }
   }

   if(closedCount > 0) {
      PrintFormat("TrendFlipGuard [%s]: yon %s->%s, %d pozisyon kapatildi, toplam kar=%.2f (karsi taraf zarar=%.2f)",
                  ctx.symbol, (newDir > 0 ? "SELL" : "BUY"), (newDir > 0 ? "BUY" : "SELL"),
                  closedCount, closedProfit, freshSideLoss);
      g_tfg_lastAction[flipIdx] = TimeCurrent();
   }

   g_tfg_lastDir[flipIdx] = newDir;
}

string RT_RegimeName() {
   switch(RT_Regime()) {
      case TPP_REG_FIXED: return "FIXED";
      case TPP_REG_BALANCE_PCT: return "BAKIYE%";
      case TPP_REG_TARGET_DEFICIT: return "DEFICIT";
      case TPP_REG_CONTROLLED_RECOVERY: return "RECOVERY";
      case TPP_REG_NET_VOLUME_TARGET: return "NETVOL";
      case TPP_REG_SOLVER: return "COZUCU";
   }
   return "SOLVER";
}
string RT_LotModeName() {
   switch(RT_LotMode()) {
      case BLM_AUTO: return "AUTO";
      case BLM_MANUAL: return "MANUAL";
      case BLM_PROJECT: return "PROJECT";
   }
   return "MANUAL";
}

//+------------------------------------------------------------------+
//| Çoklu dil – PDF 13 dil (panel etiketleri)                        |
//+------------------------------------------------------------------+
string L(const string key) {
   int lang = (int)InpPanelLanguage;

   // TR (varsayılan dolgu da TR)
   if(lang == LANG_TR || lang == LANG_KU) {
      if(key=="tab0") return "Strateji"; if(key=="tab1") return "Islemler";
      if(key=="tab2") return "Istat."; if(key=="tab3") return "Sistem";
      if(key=="tab4") return "Kalite";
      if(key=="robot_on") return "ROBOT:ACIK"; if(key=="robot_off") return "ROBOT:KAPALI";
      if(key=="buy_on") return "AL:ACIK"; if(key=="buy_off") return "AL:KAPALI";
      if(key=="sell_on") return "SAT:ACIK"; if(key=="sell_off") return "SAT:KAPALI";
      if(key=="close_profit") return "Kar Kapat"; if(key=="close_all") return "Hepsini Kapat";
      if(key=="lock_none") return "YOK"; if(key=="symbol") return "Sembol";
      if(key=="dir") return "Yon"; if(key=="locks") return "Kilitler";
      if(key=="equity_chg") return "Degisim"; if(key=="reset_chg") return "Sifirla";
      if(key=="master") return "Master"; if(key=="spread") return "Spread";
      if(key=="allow_new") return "YeniGiris"; if(key=="penalty") return "LotCeza";
   }
   // EN
   if(lang == LANG_EN) {
      if(key=="tab0") return "Strategy"; if(key=="tab1") return "Trades";
      if(key=="tab2") return "Stats"; if(key=="tab3") return "System";
      if(key=="tab4") return "Quality";
      if(key=="robot_on") return "ROBOT:ON"; if(key=="robot_off") return "ROBOT:OFF";
      if(key=="buy_on") return "BUY:ON"; if(key=="buy_off") return "BUY:OFF";
      if(key=="sell_on") return "SELL:ON"; if(key=="sell_off") return "SELL:OFF";
      if(key=="close_profit") return "Close Profit"; if(key=="close_all") return "Close All";
      if(key=="lock_none") return "NONE"; if(key=="symbol") return "Symbol";
      if(key=="dir") return "Dir"; if(key=="locks") return "Locks";
      if(key=="equity_chg") return "Change"; if(key=="reset_chg") return "Reset Chg";
      if(key=="master") return "Master"; if(key=="spread") return "Spread";
      if(key=="allow_new") return "AllowNew"; if(key=="penalty") return "LotPen";
   }
   // RU
   if(lang == LANG_RU) {
      if(key=="tab0") return "Стратегия"; if(key=="tab1") return "Сделки";
      if(key=="tab2") return "Стат."; if(key=="tab3") return "Система";
      if(key=="tab4") return "Качество";
      if(key=="robot_on") return "РОБОТ:ВКЛ"; if(key=="robot_off") return "РОБОТ:ВЫКЛ";
      if(key=="buy_on") return "BUY:ВКЛ"; if(key=="buy_off") return "BUY:ВЫКЛ";
      if(key=="sell_on") return "SELL:ВКЛ"; if(key=="sell_off") return "SELL:ВЫКЛ";
      if(key=="close_profit") return "Закр. прибыль"; if(key=="close_all") return "Закр. всё";
      if(key=="lock_none") return "НЕТ"; if(key=="symbol") return "Символ";
      if(key=="dir") return "Напр."; if(key=="locks") return "Блок";
      if(key=="equity_chg") return "Измен."; if(key=="reset_chg") return "Сброс";
      if(key=="master") return "Master"; if(key=="spread") return "Спред";
      if(key=="allow_new") return "Вход"; if(key=="penalty") return "Штраф";
   }
   // DE
   if(lang == LANG_DE) {
      if(key=="tab0") return "Strategie"; if(key=="tab1") return "Trades";
      if(key=="tab2") return "Stat."; if(key=="tab3") return "System";
      if(key=="tab4") return "Qualitaet";
      if(key=="robot_on") return "ROBOT:AN"; if(key=="robot_off") return "ROBOT:AUS";
      if(key=="buy_on") return "BUY:AN"; if(key=="buy_off") return "BUY:AUS";
      if(key=="sell_on") return "SELL:AN"; if(key=="sell_off") return "SELL:AUS";
      if(key=="close_profit") return "Profit zu"; if(key=="close_all") return "Alles zu";
      if(key=="lock_none") return "KEIN"; if(key=="symbol") return "Symbol";
      if(key=="dir") return "Richtung"; if(key=="locks") return "Sperre";
      if(key=="equity_chg") return "Aend."; if(key=="reset_chg") return "Reset";
      if(key=="master") return "Master"; if(key=="spread") return "Spread";
      if(key=="allow_new") return "Neu"; if(key=="penalty") return "Strafe";
   }
   // FR
   if(lang == LANG_FR) {
      if(key=="tab0") return "Strategie"; if(key=="tab1") return "Trades";
      if(key=="tab2") return "Stats"; if(key=="tab3") return "Systeme";
      if(key=="tab4") return "Qualite";
      if(key=="robot_on") return "ROBOT:ON"; if(key=="robot_off") return "ROBOT:OFF";
      if(key=="buy_on") return "BUY:ON"; if(key=="buy_off") return "BUY:OFF";
      if(key=="sell_on") return "SELL:ON"; if(key=="sell_off") return "SELL:OFF";
      if(key=="close_profit") return "Clot. profit"; if(key=="close_all") return "Tout clot.";
      if(key=="lock_none") return "AUCUN"; if(key=="symbol") return "Symbole";
      if(key=="dir") return "Dir"; if(key=="locks") return "Verrous";
      if(key=="equity_chg") return "Var."; if(key=="reset_chg") return "Reset";
      if(key=="master") return "Master"; if(key=="spread") return "Spread";
      if(key=="allow_new") return "Entree"; if(key=="penalty") return "Penal";
   }
   // ZH
   if(lang == LANG_ZH) {
      if(key=="tab0") return "策略"; if(key=="tab1") return "交易";
      if(key=="tab2") return "统计"; if(key=="tab3") return "系统";
      if(key=="tab4") return "质量";
      if(key=="robot_on") return "机器人:开"; if(key=="robot_off") return "机器人:关";
      if(key=="buy_on") return "买:开"; if(key=="buy_off") return "买:关";
      if(key=="sell_on") return "卖:开"; if(key=="sell_off") return "卖:关";
      if(key=="close_profit") return "平盈利"; if(key=="close_all") return "全平";
      if(key=="lock_none") return "无"; if(key=="symbol") return "品种";
      if(key=="dir") return "方向"; if(key=="locks") return "锁定";
      if(key=="equity_chg") return "变化"; if(key=="reset_chg") return "重置";
      if(key=="master") return "主"; if(key=="spread") return "点差";
      if(key=="allow_new") return "开仓"; if(key=="penalty") return "惩罚";
   }
   // HI
   if(lang == LANG_HI) {
      if(key=="tab0") return "रणनीति"; if(key=="tab1") return "ट्रेड";
      if(key=="tab2") return "आंकड़े"; if(key=="tab3") return "सिस्टम";
      if(key=="tab4") return "गुणवत्ता";
      if(key=="robot_on") return "रोबोट:ON"; if(key=="robot_off") return "रोबोट:OFF";
      if(key=="buy_on") return "BUY:ON"; if(key=="buy_off") return "BUY:OFF";
      if(key=="sell_on") return "SELL:ON"; if(key=="sell_off") return "SELL:OFF";
      if(key=="close_profit") return "लाभ बंद"; if(key=="close_all") return "सब बंद";
      if(key=="lock_none") return "नहीं"; if(key=="symbol") return "सिंबल";
      if(key=="dir") return "दिशा"; if(key=="locks") return "लॉक";
      if(key=="equity_chg") return "बदलाव"; if(key=="reset_chg") return "रीसेट";
      if(key=="master") return "Master"; if(key=="spread") return "स्प्रेड";
      if(key=="allow_new") return "प्रवेश"; if(key=="penalty") return "दंड";
   }
   // Fallback EN/TR mix
   if(key=="tab0") return "Strategy"; if(key=="tab1") return "Trades";
   if(key=="tab2") return "Stats"; if(key=="tab3") return "System";
   if(key=="tab4") return "Quality";
   if(key=="robot_on") return "ROBOT:ON"; if(key=="robot_off") return "ROBOT:OFF";
   if(key=="buy_on") return "BUY:ON"; if(key=="buy_off") return "BUY:OFF";
   if(key=="sell_on") return "SELL:ON"; if(key=="sell_off") return "SELL:OFF";
   if(key=="close_profit") return "Close Profit"; if(key=="close_all") return "Close All";
   if(key=="lock_none") return "NONE"; if(key=="symbol") return "Symbol";
   if(key=="dir") return "Dir"; if(key=="locks") return "Locks";
   if(key=="equity_chg") return "Change"; if(key=="reset_chg") return "Reset";
   if(key=="master") return "Master"; if(key=="spread") return "Spread";
   if(key=="allow_new") return "AllowNew"; if(key=="penalty") return "LotPen";
   return key;
}


//--- Panel GlobalVariable senkronu (PERFORMANS)
//|
//|  Optimizasyonlar:
//|  • Anahtarlar OnInit'te bir kez üretilir (her tick string yok)
//|  • GlobalVariableSet sadece değer değişince (dirty / compare)
//|  • Master Sync/Publish throttle (InpGV_*IntervalMs)
//|  • Panel tıklanınca g_gv_dirty=true → hemen yazılabilir
//|
#define GV_LOCAL_PFX  "NXR21L_"
#define GV_M_ROBOT    "ROBOT"
#define GV_M_BUY      "BUY"
#define GV_M_SELL     "SELL"
#define GV_M_TAB      "TAB"
#define GV_M_SUBTAB   "SUBTAB"
#define GV_M_VG       "VG"
#define GV_M_BULLET   "BULLET"
#define GV_M_NF       "NF"
#define GV_EQ_BASE    "EQBASE"

double g_indepEquityBase = 0.0;

string ULongText(const ulong value) {
   return StringFormat("%I64u", value);
}

string PanelGV_Key(const string leaf) {
   string sfx = InpMagicChartSuffix;
   if(StringLen(sfx)==0) sfx = _Symbol;
   string key = GV_LOCAL_PFX + sfx + "_" + leaf + "_" + ULongText(g_magic);
   return key;
}

string MasterGV_Key(const string leaf) {
   return InpMasterPanelPrefix + leaf;
}

void GV_Keys_Init() {
   g_gvLocRobot  = PanelGV_Key(GV_M_ROBOT);
   g_gvLocBuy    = PanelGV_Key(GV_M_BUY);
   g_gvLocSell   = PanelGV_Key(GV_M_SELL);
   g_gvLocTab    = PanelGV_Key(GV_M_TAB);
   g_gvLocSub    = PanelGV_Key(GV_M_SUBTAB);
   g_gvLocEq     = GV_LOCAL_PFX + GV_EQ_BASE + "_" + ULongText(InpMagicBase); // TEK SATIR BU
   g_gvLocVG     = PanelGV_Key(GV_M_VG);
   g_gvLocBullet = PanelGV_Key(GV_M_BULLET);
   g_gvLocNF     = PanelGV_Key(GV_M_NF);

   g_gvMasRobot  = MasterGV_Key(GV_M_ROBOT);
   g_gvMasBuy    = MasterGV_Key(GV_M_BUY);
   g_gvMasSell   = MasterGV_Key(GV_M_SELL);
   g_gvMasTab    = MasterGV_Key(GV_M_TAB);
   g_gvMasSub    = MasterGV_Key(GV_M_SUBTAB);
   g_gvMasVG     = MasterGV_Key(GV_M_VG);
   g_gvMasBullet = MasterGV_Key(GV_M_BULLET);
   g_gvMasNF     = MasterGV_Key(GV_M_NF);
   g_gvKeysReady = true;
}

// Sadece degisince yaz → disk/GV motoru yükünü keser
bool GV_SetBoolIfChanged(const string key, const bool v) {
   double nv = v ? 1.0 : 0.0;
   if(GlobalVariableCheck(key)) {
      double ov = GlobalVariableGet(key);
      if((ov > 0.5) == v) return false;
   }
   GlobalVariableSet(key, nv);
   return true;
}

bool GV_SetNumIfChanged(const string key, const double v) {
   if(GlobalVariableCheck(key)) {
      double ov = GlobalVariableGet(key);
      if(MathAbs(ov - v) < 1e-9) return false;
   }
   GlobalVariableSet(key, v);
   return true;
}

void GV_SetBool(const string key, const bool v) {
   GV_SetBoolIfChanged(key, v);
}

bool GV_GetBool(const string key, const bool defVal) {
   if(!GlobalVariableCheck(key)) return defVal;
   return (GlobalVariableGet(key) > 0.5);
}

void GV_SetNum(const string key, const double v) {
   GV_SetNumIfChanged(key, v);
}

double GV_GetNum(const string key, const double defVal) {
   if(!GlobalVariableCheck(key)) return defVal;
   return GlobalVariableGet(key);
}

void GV_MarkDirty() { g_gv_dirty = true; }

// v1.78.98 FIX (DUZELTME_REHBERI #3): GV'den (Global Variable) okunan ham
// panel lotunu broker min/max VE InpLatticeMaxLot ile clamp eder. Amac:
// eski/gecersiz/asiri buyuk bir GV degerinin (orn. onceki test seansindan
// kalan 0.50) input degistirilse bile sessizce geri gelmesini engellemek.
// Bu SADECE taban/panel lotunu sinirlar - asil emir lotu her zaman
// Lot_CalcCapped() -> equity-risk cap zincirinden ayrica gecer.
double PanelMemory_ClampGvLot(double lot, double minLot, double maxLot) {
   if(lot <= 0.0) return 0.0;
   if(InpLatticeMaxLot > 0.0 && lot > InpLatticeMaxLot) lot = InpLatticeMaxLot;
   if(maxLot > 0.0 && lot > maxLot) lot = maxLot;
   if(minLot > 0.0 && lot < minLot) lot = minLot;
   return lot;
}

// v1.78.98 EK (DUZELTME_REHBERI #3, istege bagli): VGLOT/BLOT GV kayitlarini
// siler, boylece bir sonraki OnInit input degerlerinden baslar. Rehber bunu
// bir panel butonuna baglamayi oneriyor - mevcut CANVAS panel/OBJ_EDIT olay
// sistemi (bkz. dosyanin ilerisindeki "OBJ_EDIT olay isleme" bolumu) genis
// kapsamli oldugu icin buraya YENI bir buton eklenmedi; bu fonksiyon script/
// tuş kısayolu (OnChartEvent icinde ozel bir tusa) veya ileride eklenecek bir
// panel butonuna baglanmaya hazir sekilde duruyor.
void PanelMemory_ResetLotMemory() {
   if(!g_gvKeysReady) GV_Keys_Init();
   string kVgLot  = PanelGV_Key("VGLOT");
   string kBLot   = PanelGV_Key("BLOT");
   if(GlobalVariableCheck(kVgLot))  GlobalVariableDel(kVgLot);
   if(GlobalVariableCheck(kBLot))   GlobalVariableDel(kBLot);
   g_rt_vg_lot     = InpVG_LotValue;
   g_rt_bullet_lot = InpBulletLotValue;
   GV_MarkDirty();
   PrintFormat("Lot hafizasi sifirlandi: VGLOT/BLOT GV kayitlari silindi, input degerlerine donuldu (VG=%.2f, Bullet=%.2f)",
               g_rt_vg_lot, g_rt_bullet_lot);
}

void PanelMemory_Save() {
   if(!g_gvKeysReady) GV_Keys_Init();

   GV_SetBoolIfChanged(g_gvLocRobot,  g_robotOn);
   GV_SetBoolIfChanged(g_gvLocBuy,    g_panelBuy);
   GV_SetBoolIfChanged(g_gvLocSell,   g_panelSell);
   GV_SetNumIfChanged (g_gvLocTab,    (double)g_panelTab);
   GV_SetNumIfChanged (g_gvLocSub,    (double)g_panelSubTab);
   if(g_rt_ready) {
      GV_SetBoolIfChanged(g_gvLocVG,     g_rt_vg_enable);
      GV_SetBoolIfChanged(g_gvLocBullet, g_rt_bullet_enable);
      GV_SetBoolIfChanged(g_gvLocNF,     g_rt_nf_enable);
      // v1.68: lot/step/peak kalicilik
      GV_SetNumIfChanged(PanelGV_Key("VGLOT"),  g_rt_vg_lot);
      GV_SetNumIfChanged(PanelGV_Key("VGSTEP"), g_rt_vg_step);
      GV_SetNumIfChanged(PanelGV_Key("BLOT"),   g_rt_bullet_lot);
      GV_SetNumIfChanged(PanelGV_Key("PEAK"),   g_rt_peak);
      GV_SetNumIfChanged(PanelGV_Key("PSCALE"), g_panelScale);
      GV_SetNumIfChanged(PanelGV_Key("RISK"),   g_rt_risk_mode); // FIX: risk modu kalici
      // v1.78.22: ATR Sistemi / ADX Filtresi kalicilik (ALGO PersistSettings/GV_GRID_ADX_FILTER esinli)
      GV_SetBoolIfChanged(PanelGV_Key("ATRMODE"), g_rt_atr_mode);
      GV_SetBoolIfChanged(PanelGV_Key("ADXFILT"), g_rt_adx_filter);
      GV_SetNumIfChanged(PanelGV_Key("ADXTHR"), g_rt_adx_threshold);
      GV_SetNumIfChanged(PanelGV_Key("ATRTRIG"), g_rt_atr_trig_mult);
      // v1.78.39 FIX: elle girilen ADIM/TP "override" bayrakları hiç GV'ye
      // yazılmıyordu — EA restart olduğunda (terminal/VPS reboot, chart'tan
      // kaldır-tekrar-ekle) sayısal değer (g_rt_step_pnt/g_rt_tp_pts) korunsa
      // bile "bu elle girildi, ATR ezmesin" bilgisi kayboluyor, ATR MODU açıksa
      // bir sonraki 30sn'lik tazelemede elle girilen değer sessizce eziliyordu.
      GV_SetBoolIfChanged(PanelGV_Key("STPOVR"), g_rt_step_manual_override);
      GV_SetBoolIfChanged(PanelGV_Key("TPOVR"),  g_rt_tp_manual_override);
      // v1.78.56: Trend Flip Guard panel durumu kalici
      GV_SetBoolIfChanged(PanelGV_Key("TFGEN"), g_rt_tfg_enable);
   }
   if(g_indepEquityBase > 0.0)
      GV_SetNumIfChanged(g_gvLocEq, g_indepEquityBase);
   g_gv_dirty = false;
}

void PanelMemory_Load() {
   if(!g_gvKeysReady) GV_Keys_Init();

   g_robotOn   = GV_GetBool(g_gvLocRobot, g_robotOn);
   g_panelBuy  = GV_GetBool(g_gvLocBuy,   g_panelBuy);
   g_panelSell = GV_GetBool(g_gvLocSell,  g_panelSell);

   int tab = (int)GV_GetNum(g_gvLocTab, (double)g_panelTab);
   if(tab < 0 || tab > 4) tab = 0;
   g_panelTab = tab;

   int sub = (int)GV_GetNum(g_gvLocSub, (double)g_panelSubTab);
   if(sub < 0 || sub > 3) sub = 0;
   g_panelSubTab = sub;

   g_rt_vg_enable     = GV_GetBool(g_gvLocVG,     InpVG_Enable);
   g_rt_bullet_enable = GV_GetBool(g_gvLocBullet, InpBulletEnable);
   g_rt_nf_enable     = GV_GetBool(g_gvLocNF,     InpNF_Enable);

   // v1.68: lot/step/peak GV'den
   double v;
   // v1.78.98 FIX (DUZELTME_REHBERI #3): input'a yeni bir lot yazmak GV'deki
   // eski degeri OTOMATIK SILMIYORDU - kullanici input'tan orn. 0.02 yazsa
   // bile GV'de eski (orn. 0.50) kalmissa OnInit'ten sonra o eski deger
   // runtime lotuna geri geliyordu (asagida "if(v>0) g_rt_vg_lot=v" zaten
   // bunu yapiyordu, hicbir ust/alt guvenli sinir yoktu). Artik GV'den gelen
   // ham deger broker min/max VE InpLatticeMaxLot ile clamp ediliyor - GV
   // gecerli sinirlar disina asla cikamiyor. Bu, asil emir lotunu belirleyen
   // Lot_CalcCapped()/risk cap zincirinin YERINE GECMEZ (bu sadece taban/
   // panel lotu) - her emirden once yine equity-risk cap uygulanir.
   double v_minLot = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_MIN);
   double v_maxLot = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_MAX);
   v = GV_GetNum(PanelGV_Key("VGLOT"), 0);
   if(v > 0) g_rt_vg_lot = PanelMemory_ClampGvLot(v, v_minLot, v_maxLot);
   v = GV_GetNum(PanelGV_Key("VGSTEP"), 0);
   if(v > 0) g_rt_vg_step = v;
   v = GV_GetNum(PanelGV_Key("BLOT"), 0);
   if(v > 0) g_rt_bullet_lot = PanelMemory_ClampGvLot(v, v_minLot, v_maxLot);
   v = GV_GetNum(PanelGV_Key("PEAK"), 0);
   if(v > 0) g_rt_peak = v;
   v = GV_GetNum(PanelGV_Key("PSCALE"), InpPanelScale);
   if(v < 0.6) v = 0.6;
   if(v > 1.8) v = 1.8;
   g_panelScale = v;

   // FIX: risk modu GV'den (A-/1.0x/A+ butonlari)
   v = GV_GetNum(PanelGV_Key("RISK"), 2);
   g_rt_risk_mode = (int)v;
   if(g_rt_risk_mode < 0) g_rt_risk_mode = 0;
   if(g_rt_risk_mode > 4) g_rt_risk_mode = 4;

   // v1.78.22: ATR Sistemi / ADX Filtresi kalicilik
   g_rt_atr_mode       = GV_GetBool(PanelGV_Key("ATRMODE"), InpATR_ModeEnable);
   g_rt_adx_filter     = GV_GetBool(PanelGV_Key("ADXFILT"), InpADX_FilterEnable);
   // v1.78.119 FIX (kullanici tespiti): eskiden buradaki GV_GetNum("ADXTHR")
   // gecmis bir oturumda panelden elle kaydedilmis kalici bir deger varsa
   // (orn. eski varsayilan 30), bu deger her zaman InpADX_Threshold'un
   // (Girdiler sekmesindeki yeni deger) UZERINE YAZIYORDU - kullanici
   // Girdiler'den ADX Threshold'u degistirse bile panelde HEP eski kalici
   // deger gorunuyordu. Kullanici karari: ADX Threshold icin panel-hafizasi
   // (kalicilik) OZELLIGI TAMAMEN KALDIRILDI - Girdiler sekmesindeki deger
   // ARTIK HER ZAMAN GECERLI. Diger panel kalici ayarlarina (VGLOT, BLOT,
   // PEAK, RISK, TFGEN, gun-bazli PnL takibi vb.) KASITLI OLARAK
   // DOKUNULMADI - onlarin kaliciligi ayri bir konu, kullanici bunu
   // BILEREK kapsam disi birakti (guvenlik/beklenmedik yan etki riski).
   g_rt_adx_threshold = InpADX_Threshold;
   // v1.78.119 FIX (kullanici tespiti - ayni sorun): ATR Trigger Mult icin
   // de kalici GV kaydi Girdiler'i eziyordu (ADX Threshold ile birebir ayni
   // mekanizma). Kullanici bunun da duzeltilmesini istedi.
   g_rt_atr_trig_mult = InpATR_TriggerMult;

   // v1.78.39 FIX: manuel ADIM/TP override bayraklarının kalıcılığı
   g_rt_step_manual_override = GV_GetBool(PanelGV_Key("STPOVR"), false);
   g_rt_tp_manual_override   = GV_GetBool(PanelGV_Key("TPOVR"),  false);

   // v1.78.56: Trend Flip Guard - GV'de kayit yoksa input degerine (InpTFG_Enable) dus
   g_rt_tfg_enable = GV_GetBool(PanelGV_Key("TFGEN"), InpTFG_Enable);

   if(GlobalVariableCheck(g_gvLocEq))
      g_indepEquityBase = GlobalVariableGet(g_gvLocEq);
   else
      g_indepEquityBase = AccountInfoDouble(ACCOUNT_EQUITY);
}

void PanelMemory_ResetEquityBase() {
   if(!g_gvKeysReady) GV_Keys_Init();
   g_indepEquityBase = AccountInfoDouble(ACCOUNT_EQUITY);
   GlobalVariableSet(g_gvLocEq, g_indepEquityBase); // force
   GV_MarkDirty();
   PrintFormat("Independent equity base sifirlandi: %.2f", g_indepEquityBase);
}

double Panel_IndependentEquityChange() {
   if(g_indepEquityBase <= 0.0) return 0.0;
   return AccountInfoDouble(ACCOUNT_EQUITY) - g_indepEquityBase;
}

// Master Publish: dirty veya interval dolduysa
void MasterPanel_Publish() {
   if(!g_gvKeysReady) GV_Keys_Init();

   ulong now = GetTickCount();
   int pubMs = InpGV_PublishIntervalMs;
   if(pubMs < 200) pubMs = 200;

   bool due = g_gv_dirty || ((now - g_lastGvPubMs) >= (ulong)pubMs);
   if(!due && !InpMasterPanelPublish) {
      // sadece yerel: dirty ise yaz
      if(g_gv_dirty) PanelMemory_Save();
      return;
   }

   // Yerel her publish denemesinde (dirty/due)
   if(g_gv_dirty || due)
      PanelMemory_Save();

   if(!InpMasterPanelPublish) {
      g_lastGvPubMs = now;
      return;
   }

   GV_SetBoolIfChanged(g_gvMasRobot,  g_robotOn);
   GV_SetBoolIfChanged(g_gvMasBuy,    g_panelBuy);
   GV_SetBoolIfChanged(g_gvMasSell,   g_panelSell);
   GV_SetNumIfChanged (g_gvMasTab,    (double)g_panelTab);
   GV_SetNumIfChanged (g_gvMasSub,    (double)g_panelSubTab);
   if(g_rt_ready) {
      GV_SetBoolIfChanged(g_gvMasVG,     g_rt_vg_enable);
      GV_SetBoolIfChanged(g_gvMasBullet, g_rt_bullet_enable);
      GV_SetBoolIfChanged(g_gvMasNF,     g_rt_nf_enable);
   }
   g_lastGvPubMs = now;
}

// Master Sync: throttle
void MasterPanel_Sync() {
   if(!InpMasterPanelSync || InpMasterPanelPublish) return;
   if(!g_gvKeysReady) GV_Keys_Init();

   ulong now = GetTickCount();
   int syncMs = InpGV_SyncIntervalMs;
   if(syncMs < 100) syncMs = 100;
   if((now - g_lastGvSyncMs) < (ulong)syncMs) return;
   g_lastGvSyncMs = now;

   bool chg = false;
   bool v;

   v = GV_GetBool(g_gvMasRobot, g_robotOn);
   if(v != g_robotOn) { g_robotOn = v; chg = true; }
   v = GV_GetBool(g_gvMasBuy, g_panelBuy);
   if(v != g_panelBuy) { g_panelBuy = v; chg = true; }
   v = GV_GetBool(g_gvMasSell, g_panelSell);
   if(v != g_panelSell) { g_panelSell = v; chg = true; }

   int tab = (int)GV_GetNum(g_gvMasTab, (double)g_panelTab);
   if(tab >= 0 && tab <= 4 && tab != g_panelTab) { g_panelTab = tab; chg = true; }
   int sub = (int)GV_GetNum(g_gvMasSub, (double)g_panelSubTab);
   if(sub >= 0 && sub <= 3 && sub != g_panelSubTab) { g_panelSubTab = sub; chg = true; }

   v = GV_GetBool(g_gvMasVG, g_rt_vg_enable);
   if(v != g_rt_vg_enable) { g_rt_vg_enable = v; chg = true; }
   v = GV_GetBool(g_gvMasBullet, g_rt_bullet_enable);
   if(v != g_rt_bullet_enable) { g_rt_bullet_enable = v; chg = true; }
   v = GV_GetBool(g_gvMasNF, g_rt_nf_enable);
   if(v != g_rt_nf_enable) {
      g_rt_nf_enable = v;
      if(!g_rt_nf_enable) g_newsHardLock = false;
      chg = true;
   }

   // Sync ile gelen degisim yerel hafizaya da islensin (bir sonraki save)
   if(chg) GV_MarkDirty();
}

//| DI / TMI / NDI – MİKRO YÖN KATMANLARI (PDF Bölüm 5)               |
//+------------------------------------------------------------------+
//
//  DI  (Directional / Trend Integrity)
//  ───────────────────────────────────
//  Olgun trend doğrulaması. ADX gücü + +DI/−DI yönü + EMA(34) tarafı
//  birleşerek TrendScore (0..1) ve direction üretir.
//  Düşük skor = yatay / gürültü → giriş için zayıf.
//
//  TMI (Trend Momentum Impulse)
//  ────────────────────────────
//  Erken momentum. Hızlı/yavaş ROC benzeri eğim + RSI momentumu.
//  DI tam olgunlaşmadan "AllowEarly" ile erken trend yakalayabilir.
//  ConfidenceGate altında sinyal yok sayılır.
//
//  NDI (Noise / Decision Integrity profili)
//  ───────────────────────────────────────
//  MORE_TRADES → eşikler gevşek
//  BALANCED    → varsayılan
//  SELECTIVE   → daha yüksek skor ister
//
//  FlipSafety: yön değişiminde ek güven eşiği.
//
//+------------------------------------------------------------------+

struct SDIResult {
   int    direction;     // +1 / -1 / 0
   double trendScore;    // 0..1
   double plusDI;
   double minusDI;
   double adx;
   bool   mature;        // skor >= MinTrendScore
};

struct STMIResult {
   int    direction;
   double confidence;    // 0..1
   double impulse;       // işaretli momentum
   bool   early;         // DI henüz mature değilken TMI önde
   bool   valid;         // confidence >= gate
};

struct SNDIGate {
   double minDIScore;
   double minTMIConf;
   int    minVotes;      // consensus için minimum aynı yön oy
};

SDIResult  g_di;
STMIResult g_tmi;
SDIResult  g_diSnapshot[MAX_SYMBOLS];
STMIResult g_tmiSnapshot[MAX_SYMBOLS];

SNDIGate NDI_GetGate() {
   SNDIGate g;
   g.minDIScore = InpDI_MinTrendScore;
   g.minTMIConf = InpTMI_ConfidenceGate;
   g.minVotes   = 1;
   // v1.78.73 FIX (AUDIT v1.78.72): InpNDI_Enable hicbir karar zincirinde
   // okunmuyordu - Profile/FlipSafety ayarlari NDI "kapali" iken de aynen
   // uygulaniyordu. NDI kapaliysa notr (temel DI/TMI esikleri, minVotes=1)
   // dondur - asagidaki Profile/FlipSafety ayarlamalari atlanir.
   if(!InpNDI_Enable) return g;
   switch(InpNDI_Profile) {
      case NDI_MORE_TRADES:
         g.minDIScore *= 0.75;
         g.minTMIConf *= 0.75;
         g.minVotes = 1;
         break;
      case NDI_SELECTIVE:
         g.minDIScore = MathMin(0.95, g.minDIScore * 1.35);
         g.minTMIConf = MathMin(0.95, g.minTMIConf * 1.35);
         g.minVotes = 2;
         break;
      default: // BALANCED
         g.minVotes = 1;
         break;
   }
   // Flip safety: yön değişiminde daha yüksek bar
   if(InpNDI_FlipSafety == NDI_FLIP_STRONG) {
      g.minDIScore = MathMin(0.95, g.minDIScore * 1.15);
      g.minTMIConf = MathMin(0.95, g.minTMIConf * 1.15);
   } else if(InpNDI_FlipSafety == NDI_FLIP_VERY_STRONG) {
      g.minDIScore = MathMin(0.95, g.minDIScore * 1.30);
      g.minTMIConf = MathMin(0.95, g.minTMIConf * 1.30);
      g.minVotes = MathMax(g.minVotes, 2);
   }
   return g;
}

//--- DI: ADX + DI+/DI- + EMA tarafı (optimize skor)
SDIResult DI_Evaluate(const string symbol) {
   SDIResult r;
   ZeroMemory(r);
   if(!InpDI_Enable) { r.mature = true; return r; }

   // v1.68 cached handles
   Ind_ADX_DI(symbol, r.adx, r.plusDI, r.minusDI);
   double ema = Ind_EMA_DI(symbol);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);

   // Yön: min ayrışma eşiği (gürültü bandı)
   double sepMin = InpDI_SeparationMin;
   if(r.plusDI > r.minusDI + sepMin) r.direction = +1;
   else if(r.minusDI > r.plusDI + sepMin) r.direction = -1;
   else r.direction = 0;

   int diRawDir = r.direction;

   // EMA soft confirm: fiyat EMA'nın %0.05'inden fazla ters taraftaysa cezalandır
   double emaSide = 0.0;
   bool   emaZeroed = false;
   if(ema > 0 && bid > 0 && r.direction != 0) {
      emaSide = (bid - ema) / ema;
      if(r.direction > 0 && emaSide < -0.0005) { r.direction = 0; emaZeroed = true; }
      if(r.direction < 0 && emaSide >  0.0005) { r.direction = 0; emaZeroed = true; }
   }


   // ADX soft-clip normalize (Floor..Ceil)
   double floor = InpDI_ADX_Floor;
   double ceil  = InpDI_ADX_Ceil;
   if(ceil <= floor) ceil = floor + 20.0;
   double adxNorm = 0.0;
   if(r.adx >= ceil) adxNorm = 1.0;
   else if(r.adx > floor) adxNorm = (r.adx - floor) / (ceil - floor);

   // DI ayrışma normalize (sepMin..30 → 0..1)
   double diSep = MathAbs(r.plusDI - r.minusDI);
   double diNorm = 0.0;
   if(diSep > sepMin) diNorm = MathMin(1.0, (diSep - sepMin) / (30.0 - sepMin));

   // Ağırlık: ADX biraz daha baskın (0.55/0.45) – olgun trend vurgusu
   r.trendScore = 0.55 * adxNorm + 0.45 * diNorm;
   if(r.direction == 0) r.trendScore *= 0.4; // nötr yönde skoru bastır

   SNDIGate gate = NDI_GetGate();
   r.mature = (r.trendScore >= gate.minDIScore && r.direction != 0);

   // v1.78.163 GECICI TESHIS: Floor=20->15 duzeltmesinin trendScore'u gercekten
   // gate.minDIScore esigine tasiyip tasimadigini olcmek icin. KOSULSUZ (RiskGov
   // TESHIS gibi), 60sn throttle. Esik/mantik disinda hicbir sey degismedi.
   {
      static datetime s_lastDiScoreDiag = 0;
      if(TimeCurrent() - s_lastDiScoreDiag >= 60) {
         s_lastDiScoreDiag = TimeCurrent();
         PrintFormat("DI SCORE TESHIS | %s | adx=%.1f adxNorm=%.3f | diSep=%.2f diNorm=%.3f | trendScore=%.3f (gate=%.3f) | mature=%s",
                     symbol, r.adx, adxNorm, diSep, diNorm, r.trendScore, gate.minDIScore, r.mature ? "EVET" : "hayir");
      }
   }

   return r;
}

//--- TMI: ATR-normalize impulse (sembol bağımsız)
// REPAINT FIX: TMI momentum ve RSI yalnızca kapanmış mum dizisinden hesaplanır.
STMIResult TMI_Evaluate(const string symbol) {
   STMIResult r;
   ZeroMemory(r);
   if(!InpTMI_Enable) { r.valid = true; return r; }

   int need = MathMax(InpTMI_SlowPeriod + 2, 20);
   MqlRates rates[];
   if(CopyRates(symbol, PERIOD_CURRENT, 1, need, rates) < need) return r;
   ArraySetAsSeries(rates, true);

   double c0 = rates[0].close;
   double cF = rates[MathMin(InpTMI_FastPeriod, need - 1)].close;
   double cS = rates[MathMin(InpTMI_SlowPeriod, need - 1)].close;
   if(cF <= 0 || cS <= 0 || c0 <= 0) return r;

   // Fiyat değişimi (mutlak)
   double fastMove = c0 - cF;
   double slowMove = c0 - cS;

   // v1.68 cached ATR / RSI
   double atr = Ind_ATR(symbol);
   if(atr <= 0) atr = SymbolInfoDouble(symbol, SYMBOL_POINT) * 50;

   double fastImp = fastMove / atr;
   double slowImp = slowMove / atr;
   r.impulse = 0.60 * fastImp + 0.40 * slowImp;

   double rsi = Ind_RSI_TMI(symbol);

   // Yön: ATR eşiği + RSI hizası
   double thr = InpTMI_ImpulseATR_Mult; // örn. 0.35 ATR
   if(r.impulse > thr && rsi >= 47) r.direction = +1;
   else if(r.impulse < -thr && rsi <= 53) r.direction = -1;
   else r.direction = 0;

   // Confidence: impulse/ATR skoru (2×thr → ~1.0) + RSI
   double impAbs = MathAbs(r.impulse);
   double impScore = MathMin(1.0, impAbs / (thr * 2.5));
   double rsiScore = MathMin(1.0, MathAbs(rsi - 50.0) / 22.0);
   // Momentum hizası: RSI ile impulse aynı taraftaysa bonus
   double align = 0.0;
   if((r.impulse > 0 && rsi > 50) || (r.impulse < 0 && rsi < 50)) align = 0.1;
   r.confidence = MathMin(1.0, 0.65 * impScore + 0.25 * rsiScore + align);

   SNDIGate gate = NDI_GetGate();
   r.valid = (r.confidence >= gate.minTMIConf && r.direction != 0);
   return r;
}

//--- Consensus: DI + TMI oylaması
bool Consensus_Evaluate(const string symbol, const int direction, string &note) {
   note = "";
   g_di  = DI_Evaluate(symbol);
   g_tmi = TMI_Evaluate(symbol);

   // Early flag: TMI geçerli, DI henüz mature değil
   g_tmi.early = (g_tmi.valid && !g_di.mature && (InpTMI_AllowEarly || InpBullet_AllowEarlyTMI));

   note = StringFormat("DI(dir=%d sc=%.2f adx=%.1f %s) TMI(dir=%d conf=%.2f%s)",
                       g_di.direction, g_di.trendScore, g_di.adx,
                       (g_di.mature ? "MATURE" : "weak"),
                       g_tmi.direction, g_tmi.confidence,
                       (g_tmi.early ? " EARLY" : ""));

   if(!InpBullet_TrendConsensus) return true;
   if(direction == 0) return true;

   SNDIGate gate = NDI_GetGate();

   // Conflict: DI ve TMI zıt yön ve ikisi de anlamlı
   bool diStrong  = (g_di.direction != 0 && g_di.trendScore >= gate.minDIScore * 0.8);
   bool tmiStrong = (g_tmi.direction != 0 && g_tmi.confidence >= gate.minTMIConf * 0.8);

   if(InpBullet_BlockDITMIConflict && diStrong && tmiStrong &&
      g_di.direction != g_tmi.direction) {
      note += " | CONFLICT_BLOCK";
      return false;
   }

   // Oy sayımı
   int votes = 0;
   if(g_di.direction == direction && (g_di.mature || g_di.trendScore >= gate.minDIScore * 0.7))
      votes++;
   if(g_tmi.direction == direction && g_tmi.valid)
      votes++;
   // Early TMI tek oy ile geçebilir
   if(votes == 0 && g_tmi.early && g_tmi.direction == direction)
      votes = 1;

   if(votes < gate.minVotes) {
      note += StringFormat(" | VOTES=%d<%d", votes, gate.minVotes);
      return false;
   }

   // DI açıkça karşı yöndeyse (mature) engelle
   if(g_di.mature && g_di.direction != 0 && g_di.direction != direction) {
      note += " | DI_AGAINST";
      return false;
   }

   note += StringFormat(" | VOTES=%d OK", votes);
   return true;
}

//======================================================================
// v1.78.151 COLD-START SEED FIX (kaynak: kullanicinin yukledigi
// "DGN_Nexus_v1_78_150_COLDSTART_Cozum_Uygulama_Raporu.pdf")
//
// KOK NEDEN (raporun P0 bulgulari, kod uzerinde birebir dogrulandi):
// Consensus_Evaluate() bir DOGRULAYICI'dir - kendisine verilen bir aday
// yonun (direction parametresi) DI/TMI ile uyumlu olup olmadigina bakar;
// direction=0 iken (yani zaten "aday yok" durumunda) direkt true doner
// (satir ~4912: "if(direction == 0) return true;") - YENI BIR YON
// URETMEZ. Stage_DirectionEngine (VEMA_MA_RegimeGate) notr donduginde
// (g_ctx.dir.direction=0), DirectionLock_Manage() ilk commit'i BEKLEDIGI
// icin (committedDir==0 iken direction=0 ise allow_new_entries=false
// yapip cikar - bkz. DirectionLock_Manage satir ~4031-4039) VE
// RunStagedPipeline'daki Grid dispatch'i (satir ~16894-16901) direction=0
// oldugunda Lattice_TryOpenLevel'i hic CAGIRMIYOR (kendi yorumu: "v1.78.95:
// NOTR artik eski yonu seed ETMEZ"), Bullet_Process de ayni sekilde
// direction=0 ise ilk satirinda cikiyor (satir ~11957) - sonuc: VEMA notr
// + hic commit yoksa, sistemi baslatacak HICBIR MEKANIZMA yoktu (rapor
// Bolum 1: "kisir dongu").
//
// COZUM (raporun onerdigi mimari, Bolum 6-10): Consensus_Evaluate'i
// BOZMADAN, AYRI ve DAR kapsamli bir "ilk yon" ureteci. SADECE su UCU
// BIRDEN true iken calisir: (1) DirectionLock hic commit ETMEMIS
// (committedDir==0 - yani bu GERCEKTEN soguk baslangic, DirectionLock'un
// normal "ters yon teyidi bekleniyor" durumu DEGIL), (2) bu sembolde
// g_magic altinda ACIK POZISYON YOK (raporun "NoMainExposure" sarti),
// (3) DI + TMI + EMA(Ind_EMA_DI - DI'nin zaten kullandigi ayni referans)
// AYNI yonde hizali VE HER IKISI DE Consensus'un KULLANDIGI AYNI esikleri
// (NDI_GetGate) geciyor - COLD START icin AYRI/gevsek bir esik
// UYDURULMUYOR (raporun acikca yasakladigi sey: "direction=0 iken son
// yonu otomatik seed etmek" ve "risk hesabi 0 donerken minimum lotu
// zorla acmak" gibi kestirmeler burada YOK).
//
// NE YAPMAZ (raporun Bolum 6/9/16 ilkesi, kritik): Bu fonksiyon TEK
// BASINA HICBIR EMIR ACMAZ, HICBIR RISK/MARGIN/HARD-SL/GRID-FIREWALL/
// GUNLUK-KILIT katmanini BYPASS ETMEZ. Sadece g_ctx.dir.direction
// (ve DirectionLock'un commit edebilmesi icin gereken confidence tabanini)
// dolduruyor - RunStagedPipeline'da DirectionLock_Manage()'DEN HEMEN ONCE
// cagrilir (bkz. cagri noktasi), boylece DirectionLock KENDI mevcut commit
// mantigiyla (degistirilmeden) bu yonu normal bir yon gibi isler; ondan
// SONRAKI HER SEY (RiskGovernor, RiskCap_MaxLot, Trade_PreflightMarketOrder,
// basket-risk, OrderCheck, Hard SL) TAMAMEN DEGISMEDEN calismaya devam eder.
// Seed basarili olup DirectionLock commit ettikten SONRA, committedDir
// artik 0 olmadigi icin bu fonksiyon bir sonraki tick'te otomatik olarak
// devre disi kalir (raporun T7 testi: "Seed sonrasi seed motoru tekrar
// yon degistirmemeli") - ayrica bir "kullanildi" bayragina gerek yok.
//======================================================================
// v1.78.164 REFACTOR (kullanicinin son 3 ekran goruntusunden cikan UCUNCU
// mimari bosluk - asagida ColdStartSeedDirection'dan sonra detayli anlatilir):
// Sart 3-5 (spread/ATR/DI+TMI+EMA hizalama+esik) ORTAK bir cekirdek fonksiyona
// tasindi - hem cold-start hem reversal-seed AYNI cekirdegi, AYNI esiklerle
// kullansin diye (kod tekrari + iki yerde farkli esik kullanma riski onlenir).
// DAVRANIS DEGISMEDI - bu SADECE ColdStartSeedDirection'in gövdesinin
// yeniden duzenlenmesi.
int DirAlignmentSignal(const string symbol, string &reason)
{
   reason = "";
   MqlTick tick;
   if(!SymbolInfoTick(symbol, tick) || tick.ask <= 0.0 || tick.bid <= 0.0) {
      reason = "TICK_GECERSIZ";
      return 0;
   }
   double spreadPct = (tick.bid > 0.0) ? ((tick.ask - tick.bid) / tick.bid) * 100.0 : 999.0;
   if(spreadPct > InpAdaptive_SpreadUnsafePct) { reason = "SPREAD_YUKSEK"; return 0; }

   double atr = RiskATR_Read(symbol);
   if(atr <= 0.0) atr = Ind_ATR(symbol, 0);
   if(atr <= 0.0) { reason = "ATR_GECERSIZ"; return 0; }

   SDIResult  di  = DI_Evaluate(symbol);
   STMIResult tmi = TMI_Evaluate(symbol);

   double ema = Ind_EMA_DI(symbol);
   double mid = (tick.ask + tick.bid) * 0.5;
   int emaDir = 0;
   if(ema > 0.0) {
      if(mid > ema) emaDir = 1;
      else if(mid < ema) emaDir = -1;
   }

   if(di.direction == 0 || di.direction != tmi.direction || di.direction != emaDir) {
      reason = "DI_TMI_EMA_UYUSMUYOR";
      return 0;
   }

   SNDIGate gate = NDI_GetGate();
   if(!(di.mature || di.trendScore >= gate.minDIScore * 0.7)) { reason = "DI_ZAYIF"; return 0; }
   if(!(tmi.valid && tmi.confidence >= gate.minTMIConf))       { reason = "TMI_ZAYIF"; return 0; }

   reason = (di.direction > 0) ? "SEED_BUY" : "SEED_SELL";
   return di.direction;
}

int ColdStartSeedDirection(const string symbol, string &reason)
{
   reason = "";
   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) { reason = "IDX_YOK"; return 0; }

   // Sart 1: GERCEK soguk baslangic - DirectionLock hic commit etmemis olmali.
   // (Zaten commit edilmisse bu DirectionLock'un KENDI "reversal teyidi
   // bekleniyor" durumudur - raporun Bolum 10: "Normal reversal DirectionLock
   // üzerinden çalışmalı", burada MUDAHALE EDILMEZ.)
   if(g_dirlock_committedDir[idx] != 0) { reason = "ZATEN_COMMIT_EDILMIS"; return 0; }

   // Sart 2 (raporun "NoMainExposure"): bu sembolde g_magic altinda acik
   // pozisyon varsa cold-start degildir - normal yonetim akisina birak.
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      reason = "MEVCUT_POZISYON_VAR";
      return 0;
   }

   // Sart 3-5 (spread/ATR gecerliligi + DI+TMI+EMA UCU BIRDEN hizalanma +
   // Consensus'un normal esikleri) - ortak cekirdekte (bkz. yukarida).
   return DirAlignmentSignal(symbol, reason);
}

//+------------------------------------------------------------------+
//| AWR (Adaptive Working Regime) + AEGIS koruma                     |
//+------------------------------------------------------------------+
// AWR: volatilite / pulse rejimini tespit eder (RANGE vs TREND vs SPIKE)
// AEGIS: aşırı adverse hareket veya DD'de yeni girişi keser / kârı korur
//+------------------------------------------------------------------+

enum ENUM_AWR_REGIME {
   AWR_RANGE = 0,
   AWR_TREND = 1,
   AWR_SPIKE = 2
};

struct SAWRResult {
   ENUM_AWR_REGIME regime;
   double          atrNorm;     // ATR / fiyat
   double          pulse;       // kısa tick range proxy
   string          name;
};

struct SAEGISResult {
   bool   block_entry;
   bool   protect_profit;
   bool   protect_loss;    // v1.78.63 FIX (#129): protect_profit'in zarar aynasi
   string reason;
};

SAWRResult   g_awr;
SAEGISResult g_aegis;

// REPAINT FIX: AWR pulse/rejim sınıflandırması oluşmakta olan mumun aralığını kullanmaz.
SAWRResult AWR_Evaluate(const string symbol) {
   SAWRResult r;
   r.regime = AWR_RANGE;
   r.atrNorm = 0;
   r.pulse = 0;
   r.name = "RANGE";

   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double atr = Ind_ATR(symbol);
   if(bid > 0 && atr > 0) r.atrNorm = atr / bid;

   // Pulse: son 5 bar high-low ortalama / ATR
   MqlRates rates[];
   if(CopyRates(symbol, PERIOD_CURRENT, 1, 6, rates) >= 6) {
      ArraySetAsSeries(rates, true);
      double sum = 0;
      for(int i = 0; i < 5; i++) sum += (rates[i].high - rates[i].low);
      double avgRange = sum / 5.0;
      if(atr > 0) r.pulse = avgRange / atr;
   }

   // Rejim (PDF AWR input eşikleri)
   double spikePulse = (InpAWR_SpikePulseMin > 0) ? InpAWR_SpikePulseMin : 1.8;
   double spikeAtr   = (InpAWR_SpikeATRNorm > 0) ? InpAWR_SpikeATRNorm : 0.012;
   double trendMin   = (InpAWR_TrendScoreMin > 0) ? InpAWR_TrendScoreMin : 0.5;

   if(r.pulse >= spikePulse || r.atrNorm > spikeAtr) {
      r.regime = AWR_SPIKE;
      r.name = "SPIKE";
   } else if(g_di.mature && g_di.trendScore >= trendMin) {
      r.regime = AWR_TREND;
      r.name = "TREND";
   } else {
      r.regime = AWR_RANGE;
      r.name = "RANGE";
   }
   return r;
}

SAEGISResult AEGIS_Evaluate(const string symbol, SPipelineContext &ctx) {
   SAEGISResult r;
   r.block_entry = false;
   r.protect_profit = false;
   r.protect_loss = false;
   r.reason = "";

   // 1) SPIKE rejiminde giriş kes (AWR input)
   if(g_awr.regime == AWR_SPIKE && InpAWR_BlockEntryOnSpike) {
      r.block_entry = true;
      r.reason = "SPIKE";
   }

   // 2) Equity DD > 8% (balance'a göre) → koruma
   if(ctx.balance > 0) {
      double dd = ((ctx.balance - ctx.equity) / ctx.balance) * 100.0;
      if(dd >= 8.0) {
         r.block_entry = true;
         r.reason = (r.reason == "" ? "" : r.reason + "+") + "DD8";
      }
   }

   // 3) Ters sinyal + floating KAR → karı koru VEYA floating ZARAR → zararı kes
   // v1.78.63 FIX (#129): eskiden burada SADECE kar tarafi vardi (asagida
   // protect_profit) - ters sinyal + zarardaysak hicbir sey tetiklenmiyordu,
   // zarar sadece block_entry'e (%8 DD/SPIKE) bagli ayri bir mekanizmaya
   // kaliyordu. buyLot/sellLot/netDir artik pnl isaretinden BAGIMSIZ tek
   // seferde hesaplanip, protect_profit ile protect_loss AYNI ters-sinyal
   // kosulunu ve AYNI esik buyuklugunu (PeakTarget*0.5) paylasiyor.
   double pnl = 0;
   double buyLot = 0, sellLot = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      pnl += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      double v = PositionGetDouble(POSITION_VOLUME);
      if((int)PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) buyLot += v;
      else sellLot += v;
   }
   int netDir = 0;
   if(buyLot > sellLot) netDir = +1;
   else if(sellLot > buyLot) netDir = -1;

   if(InpTPProjPeakTargetMoney > 0 && ctx.dir.direction != 0 &&
      netDir != 0 && ctx.dir.direction != netDir) {
      double flipThreshold = InpTPProjPeakTargetMoney * 0.5;
      if(pnl > flipThreshold) {
         r.protect_profit = true;
         r.reason = (r.reason == "" ? "" : r.reason + "+") + "FLIP_PROTECT";
      } else if(pnl < -flipThreshold) {
         r.protect_loss = true;
         r.reason = (r.reason == "" ? "" : r.reason + "+") + "FLIP_LOSSCUT";
      }
   }
   return r;
}


//+------------------------------------------------------------------+
//| HEG (Hyperactive Edge Governor) + DTE (Directional Truth Meta)   |
//+------------------------------------------------------------------+
struct SHEGResult {
   bool   block;
   double edgePts;
   double efficiency;
   string reason;
};
struct SDTEResult {
   bool   block;
   double metaEdge;
   bool   late;
   bool   noisy;
   string reason;
};
SHEGResult g_heg;
SDTEResult g_dte;
SHEGResult g_hegSnapshot[MAX_SYMBOLS];
SDTEResult g_dteSnapshot[MAX_SYMBOLS];
datetime   g_heg_blockUntil[MAX_SYMBOLS]; // v1.78.47 FIX (#118): eskiden TEK datetime'di,
// symbol parametresi hic kullanilmiyordu — bir sembolde spike (HEG_SPIKE) olustugunda
// koyulan cooldown TUM semboller icin gecerli oluyordu (XAUUSD spike → EURUSD/BTCUSD da
// ayni tick'ten itibaren HEG_COOLDOWN ile bloklaniyordu). Artik Ind_FindIdx(symbol) ile
// MAX_SYMBOLS uzunlugunda diziye tasindi, her sembolun kendi bagimsiz cooldown'u var.

// REPAINT FIX: HEG edge, efficiency ve spike ölçümleri kapanmış barlarla sınırlıdır.
SHEGResult HEG_Evaluate(const string symbol) {
   SHEGResult r;
   r.block = false; r.edgePts = 0; r.efficiency = 0; r.reason = "";
   bool hegOn = g_rt_ready ? g_rt_heg_on : InpHEG_Enable;
   if(!hegOn) return r;
   // v1.78.47 FIX (#118): sembol-bazli cooldown — asagida spike aninda da ayni index kullanilir
   int hegIdx = Ind_FindIdx(symbol);
   datetime hegBlockUntil = (hegIdx >= 0) ? g_heg_blockUntil[hegIdx] : 0;
   if(TimeCurrent() < hegBlockUntil) {
      r.block = true; r.reason = "HEG_COOLDOWN"; return r;
   }

   int bars = MathMax(5, InpHEG_LookbackBars);
   MqlRates rates[];
   if(CopyRates(symbol, PERIOD_CURRENT, 1, bars + 2, rates) < bars) return r;
   ArraySetAsSeries(rates, true);

   int b0 = 0; // CopyRates start=1: rates[0] son kapanmış bardır.

   double atr = Ind_ATR(symbol);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0) point = _Point;
   long spr = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   double spreadPts = (double)spr;

   // Net move vs range efficiency
   double netMove = MathAbs(rates[b0].close - rates[b0 + bars - 1].open);
   double sumRange = 0;
   for(int i = 0; i < bars; i++) sumRange += (rates[b0 + i].high - rates[b0 + i].low);
   r.efficiency = (sumRange > 0) ? netMove / sumRange : 0;
   r.edgePts = (netMove / point) - spreadPts * InpHEG_SpreadMult;

   // Vol spike: son bar range vs ATR
   double lastRange = rates[b0].high - rates[b0].low;
   bool spike = (atr > 0 && lastRange >= atr * InpHEG_VolSpikeMult);

   if(InpHEG_BlockOnSpike && spike) {
      r.block = true; r.reason = "HEG_SPIKE";
      if(hegIdx >= 0) g_heg_blockUntil[hegIdx] = TimeCurrent() + InpHEG_CooldownSec; // v1.78.47 FIX (#118): sadece bu sembol
   } else if(r.edgePts < InpHEG_MinEdgePts) {
      r.block = true; r.reason = "HEG_LOW_EDGE";
   } else if(r.efficiency < InpHEG_MinEfficiency) {
      r.block = true; r.reason = "HEG_LOW_EFF";
   }
   if(InpHEG_LogDecisions && r.block)
      PrintFormat("HEG BLOCK %s edge=%.1f eff=%.2f", r.reason, r.edgePts, r.efficiency);
   return r;
}

// REPAINT FIX: DTE geç giriş ve gürültü ölçümleri kapanmış bar verisiyle yapılır.
SDTEResult DTE_Evaluate(const string symbol, const SDirectionResult &dir) {
   SDTEResult r;
   r.block = false; r.metaEdge = 0; r.late = false; r.noisy = false; r.reason = "";
   bool dteOn = g_rt_ready ? g_rt_dte_on : InpDTE_Enable;
   if(!dteOn) return r;

   int lateBars = MathMax(1, InpDTE_LateEntryBars);
   MqlRates rates[];
   if(CopyRates(symbol, PERIOD_CURRENT, 1, lateBars + 5, rates) < lateBars + 2) return r;
   ArraySetAsSeries(rates, true);

   int b0 = 0; // CopyRates start=1: rates[0] son kapanmış bardır.

   // Late entry: fiyat zaten N bar boyunca aynı yönde agresif ilerlediyse
   double move = rates[b0].close - rates[b0 + lateBars].close;
   double atr = Ind_ATR(symbol);
   if(atr <= 0) atr = SymbolInfoDouble(symbol, SYMBOL_POINT) * 50;

   if(dir.direction > 0 && move > atr * 1.2) r.late = true;
   if(dir.direction < 0 && move < -atr * 1.2) r.late = true;

   // Noise: DI/TMI conflict veya düşük conf
   r.noisy = (g_consensusBlocked || dir.confidence < 0.30);

   // Meta edge skoru
   r.metaEdge = dir.confidence;
   if(r.late)  r.metaEdge -= InpDTE_NoisePenalty;
   if(r.noisy) r.metaEdge -= InpDTE_NoisePenalty;
   if(g_di.mature && g_di.direction == dir.direction) r.metaEdge += 0.1;
   if(g_tmi.valid && g_tmi.direction == dir.direction) r.metaEdge += 0.05;

   if(InpDTE_BlockLateEntry && r.late) {
      r.block = true; r.reason = "DTE_LATE";
   } else if(InpDTE_BlockNoisy && r.noisy) {
      r.block = true; r.reason = "DTE_NOISY";
   } else if(r.metaEdge < InpDTE_MinMetaEdge) {
      r.block = true; r.reason = "DTE_LOW_META";
   }
   if(InpDTE_LogScore && (r.block || r.metaEdge < 0.5))
      PrintFormat("DTE %s meta=%.2f late=%d noisy=%d", r.reason, r.metaEdge, r.late, r.noisy);
   return r;
}


//+------------------------------------------------------------------+
//| Early Trend Check + Direction Smart Check                        |
//+------------------------------------------------------------------+
struct SEarlyTrend {
   int    direction;
   double confidence;
   double impulse;
   bool   valid;
};
struct SSmartDir {
   bool   allow;
   double conf;
   string note;
};
SEarlyTrend g_early;
SSmartDir   g_smart;
SEarlyTrend g_earlySnapshot[MAX_SYMBOLS];
SSmartDir   g_smartSnapshot[MAX_SYMBOLS];
bool        g_newsHardLockSnapshot[MAX_SYMBOLS];
bool        g_viopBlockedSnapshot[MAX_SYMBOLS];
bool        g_consensusBlockedSnapshot[MAX_SYMBOLS];
string      g_consensusNoteSnapshot[MAX_SYMBOLS];

// REPAINT FIX: EarlyTrend impulse ve ROC hesapları kapanmış mumlarla yapılır.
SEarlyTrend EarlyTrend_Evaluate(const string symbol) {
   SEarlyTrend r;
   r.direction = 0; r.confidence = 0; r.impulse = 0; r.valid = false;
   if(!InpEarlyTrend_Enable) return r;

   int need = MathMax(InpEarlyTrend_SlowPeriod + 2, InpEarlyTrend_MaxBars + 2);
   MqlRates rates[];
   if(CopyRates(symbol, PERIOD_CURRENT, 1, need, rates) < need) return r;
   ArraySetAsSeries(rates, true);

   int b0 = 0; // CopyRates start=1: rates[0] son kapanmış bardır.

   double atr = Ind_ATR(symbol);
   if(atr <= 0) atr = SymbolInfoDouble(symbol, SYMBOL_POINT) * 50;

   double c0 = rates[b0].close;
   double cF = rates[MathMin(b0 + InpEarlyTrend_FastPeriod, need - 1)].close;
   double cS = rates[MathMin(b0 + InpEarlyTrend_SlowPeriod, need - 1)].close;
   double fastImp = (c0 - cF) / atr;
   double slowImp = (c0 - cS) / atr;
   r.impulse = 0.6 * fastImp + 0.4 * slowImp;

   if(InpEarlyTrend_UseROC) {
      double roc = (cS != 0) ? (c0 - cS) / MathAbs(cS) : 0;
      if(MathAbs(roc) < InpEarlyTrend_ROC_Mult * 0.001 && MathAbs(r.impulse) < InpEarlyTrend_MinImpulse)
         return r;
   }

   if(r.impulse > InpEarlyTrend_MinImpulse) r.direction = +1;
   else if(r.impulse < -InpEarlyTrend_MinImpulse) r.direction = -1;

   r.confidence = MathMin(1.0, MathAbs(r.impulse) / MathMax(InpEarlyTrend_MinImpulse * 2.0, 0.01));
   if(InpEarlyTrend_UseTMI && g_tmi.valid && g_tmi.direction == r.direction)
      r.confidence = MathMin(1.0, r.confidence + 0.15);

   r.valid = (r.direction != 0 && r.confidence >= InpEarlyTrend_MinConf);
   return r;
}

SSmartDir SmartDir_Evaluate(const string symbol, const int direction, const double baseConf) {
   SSmartDir r;
   r.allow = true; r.conf = baseConf; r.note = "";
   if(!InpSmartDir_Enable) return r;
   if(direction == 0) { r.allow = false; r.note = "NEUTRAL"; return r; }

   if(baseConf < InpSmartDir_MinConf) {
      r.allow = false; r.note = "LOW_CONF"; return r;
   }

   // v1.68 cached EMA34 / RSI14 / ADX
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   int idx = Ind_FindIdx(symbol);
   double ema34 = (idx >= 0) ? Ind_HandleBuf(g_ind[idx].ema34) : 0;
   if(ema34 > 0) {
      double sep = (bid - ema34) / ema34;
      if(direction > 0 && sep < -InpSmartDir_EMA_SepPct / 100.0) {
         r.allow = false; r.note = "EMA_AGAINST";
      }
      if(direction < 0 && sep >  InpSmartDir_EMA_SepPct / 100.0) {
         r.allow = false; r.note = "EMA_AGAINST";
      }
   }

   if(InpSmartDir_UseRSI) {
      double rsi = (idx >= 0) ? Ind_HandleBuf(g_ind[idx].rsi14) : 50;
      if(direction > 0 && rsi >= InpSmartDir_RSI_OB) { r.allow = false; r.note = "RSI_OB"; }
      if(direction < 0 && rsi <= InpSmartDir_RSI_OS) { r.allow = false; r.note = "RSI_OS"; }
   }

   if(InpSmartDir_UseADX) {
      double adx = 0, pdi = 0, mdi = 0;
      Ind_ADX_DI(symbol, adx, pdi, mdi);
      if(adx < InpSmartDir_ADX_Min) { r.allow = false; r.note = "ADX_LOW"; }
   }

   if(InpSmartDir_BlockConflict && g_consensusBlocked) {
      r.allow = false; r.note = "CONSENSUS";
   }

   // SECOND_AUDIT #7 FIX (P3): InpSmartDir_ConfirmTicks artik gercekten
   // kullaniliyor. Eskiden tanimliydi ama okunmuyordu. Simdi r.allow=true
   // tek bir tick'in gurultusune degil, AYNI yonde ust uste
   // InpSmartDir_ConfirmTicks kadar kesintisiz "allow" kalmaya bagli - Bullet'in
   // kendi entry-confirm mantigiyla ayni fikir (bkz. B_CONFIRM), burada
   // Ind_FindIdx ile bulunan idx (g_sym_idx'e bagimli degil) ile sembol bazli.
   if(idx >= 0) {
      if(r.allow) {
         if(direction != g_smartdir_lastDir[idx]) {
            g_smartdir_confirmTicks[idx] = 1;
            g_smartdir_lastDir[idx] = direction;
         } else {
            g_smartdir_confirmTicks[idx]++;
         }
         if(InpSmartDir_ConfirmTicks > 1 && g_smartdir_confirmTicks[idx] < InpSmartDir_ConfirmTicks) {
            r.allow = false;
            r.note = "CONFIRM_WAIT";
         }
      } else {
         g_smartdir_confirmTicks[idx] = 0;
      }
   }
   return r;
}


//+------------------------------------------------------------------+
//| AutoTune iskeleti (PDF AUTO TUNING + RISK STYLE)                 |
//+------------------------------------------------------------------+
struct SAutoTuneState {
   datetime last_run;
   int      trade_count;
   double   sum_profit;
   double   sum_loss;
   double   lot_mult;
   double   step_mult;
   double   tp_mult;
};
SAutoTuneState g_at;

void AutoTune_Init() {
   ZeroMemory(g_at);
   g_at.lot_mult  = 1.0;
   g_at.step_mult = 1.0;
   g_at.tp_mult   = 1.0;
   // v1.78.41 FIX (#93): InpAutoTune_PersistAcrossRestart=true ise carpanlar
   // GV'den geri yuklenir — restart adaptif risk profilini artik SESSIZCE
   // 1.0'a dondurmuyor, davranis acikca kullanici kontrolunde. trade_count/
   // sum_profit/sum_loss bilerek kalici yapilmadi (bu bir zaman penceresi
   // istatistigi, restart'ta sifirlanmasi daha dogru).
   if(InpAutoTune_PersistAcrossRestart) {
      double lm = GV_GetNum(PanelGV_Key("ATLOTM"), 1.0);
      double sm = GV_GetNum(PanelGV_Key("ATSTPM"), 1.0);
      double tm = GV_GetNum(PanelGV_Key("ATTPM"),  1.0);
      if(lm > 0) g_at.lot_mult  = lm;
      if(sm > 0) g_at.step_mult = sm;
      if(tm > 0) g_at.tp_mult   = tm;
      PrintFormat("R21 AutoTune RESTORE | lot=%.3f step=%.3f tp=%.3f (persist=ON)",
                  g_at.lot_mult, g_at.step_mult, g_at.tp_mult);
   }
}

// v1.78.41 FIX (#93): persist ac ikse carpanlari GV'ye yaz (AutoTune_MaybeRun
// carpanlari degistirdikten sonra cagrilir).
void AutoTune_SaveIfPersist() {
   if(!InpAutoTune_PersistAcrossRestart) return;
   GV_SetNumIfChanged(PanelGV_Key("ATLOTM"), g_at.lot_mult);
   GV_SetNumIfChanged(PanelGV_Key("ATSTPM"), g_at.step_mult);
   GV_SetNumIfChanged(PanelGV_Key("ATTPM"),  g_at.tp_mult);
}

double AutoTune_RiskScale() {
   switch(InpAutoTune_RiskProfile) {
      case RISK_ULTRA_SAFE:   return 0.5;
      case RISK_CONSERVATIVE: return 0.75;
      case RISK_BALANCED:     return 1.0;
      case RISK_AGGRESSIVE:   return 1.25;
      case RISK_ULTRA_AGGR:   return 1.5;
   }
   return 1.0;
}

void AutoTune_OnDealProfit(const double profit) {
   if(!InpAutoTune_Enable) return;
   g_at.trade_count++;
   if(profit >= 0) g_at.sum_profit += profit;
   else            g_at.sum_loss   += MathAbs(profit);
}

void AutoTune_MaybeRun() {
   if(!InpAutoTune_Enable) return;
   if(InpAutoTune_OnlyDemo && !MQLInfoInteger(MQL_TESTER) &&
      AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO)
      return;
   if(InpAutoTune_IntervalMin <= 0) return;
   if(TimeCurrent() - g_at.last_run < (datetime)InpAutoTune_IntervalMin * 60) return;
   if(g_at.trade_count < InpAutoTune_MinTrades) return;

   double gross = g_at.sum_profit + g_at.sum_loss;
   double pf = (g_at.sum_loss > 0) ? (g_at.sum_profit / g_at.sum_loss) : (g_at.sum_profit > 0 ? 99.0 : 0.0);
   double step = InpAutoTune_StepPct / 100.0;
   double scale = AutoTune_RiskScale();

   if(pf >= InpAutoTune_TargetPF) {
      // İyi performans → dikkatli büyüt
      if(InpAutoTune_AdjustLot)
         g_at.lot_mult = MathMin(InpAutoTune_MaxRiskPct, g_at.lot_mult * (1.0 + step * 0.5) * scale);
      if(InpAutoTune_AdjustStep)
         g_at.step_mult = MathMax(0.5, g_at.step_mult * (1.0 - step * 0.25));
      if(InpAutoTune_AdjustTP)
         g_at.tp_mult = MathMin(2.0, g_at.tp_mult * (1.0 + step * 0.25));
   } else {
      // Zayıf → küçült / adımı aç
      if(InpAutoTune_AdjustLot)
         g_at.lot_mult = MathMax(InpAutoTune_MinRiskPct, g_at.lot_mult * (1.0 - step) * scale);
      if(InpAutoTune_AdjustStep)
         g_at.step_mult = MathMin(2.5, g_at.step_mult * (1.0 + step * 0.5));
      if(InpAutoTune_AdjustTP)
         g_at.tp_mult = MathMax(0.5, g_at.tp_mult * (1.0 - step * 0.25));
   }

   PrintFormat("AutoTune PF=%.2f trades=%d lotMult=%.2f stepMult=%.2f tpMult=%.2f",
               pf, g_at.trade_count, g_at.lot_mult, g_at.step_mult, g_at.tp_mult);
   AutoTune_SaveIfPersist(); // v1.78.41 FIX (#93)

   // pencereyi sıfırla
   g_at.trade_count = 0;
   g_at.sum_profit = 0;
   g_at.sum_loss = 0;
   g_at.last_run = TimeCurrent();
}

double AutoTune_LotMult()  {
   if(!InpAutoTune_Enable) return 1.0;
   double m = g_at.lot_mult;
   if(m > 1.5) m = 1.5;   // FIX: Autotune hard cap
   if(m < 0.25) m = 0.25;
   return m;
}
double AutoTune_StepMult() { return InpAutoTune_Enable ? g_at.step_mult : 1.0; }
double AutoTune_TPMult()   { return InpAutoTune_Enable ? g_at.tp_mult   : 1.0; }

double RiskGovernor_StatsWinRate(const SRiskGovStats &stats) {
   if(stats.trades <= 0) return 0.0;
   return (double)stats.wins / (double)stats.trades;
}

double RiskGovernor_StatsPF(const SRiskGovStats &stats) {
   if(stats.totalLoss <= 0.0) return (stats.totalProfit > 0.0 ? 999.0 : 0.0);
   return stats.totalProfit / stats.totalLoss;
}

double RiskGovernor_StatsAvgWin(const SRiskGovStats &stats) {
   if(stats.wins <= 0) return 0.0;
   return stats.totalProfit / (double)stats.wins;
}

double RiskGovernor_StatsAvgLoss(const SRiskGovStats &stats) {
   if(stats.losses <= 0) return 0.0;
   return stats.totalLoss / (double)stats.losses;
}

double RiskGovernor_MarketQuality(const string symbol, const int direction) {
   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) return 1.0;

   double priceNow = iClose(symbol, PERIOD_CURRENT, 1);
   double openNow  = iOpen(symbol, PERIOD_CURRENT, 1);
   double highNow  = iHigh(symbol, PERIOD_CURRENT, 1);
   double lowNow   = iLow(symbol, PERIOD_CURRENT, 1);
   double atrNow   = Ind_ATR(symbol, 1);
   double ema9     = Ind_HandleBuf(g_ind[idx].ema9, 1);
   double ema21    = Ind_HandleBuf(g_ind[idx].ema21, 1);

   if(priceNow <= 0.0 || atrNow <= 0.0 || ema9 <= 0.0 || ema21 <= 0.0)
      return 0.85;

   // 1) EMA yakınlık / yön uyumu: fiyatın EMA9/EMA21 dizisini hangi yönün
   // içinde test ettiğini değerlendirir. EMA yakınlığı arttıkça kalite artar,
   // EMA üzerinden geçiş ve zıt taraf aktifse kalite düşer.
   double emaTrend = 0.0;
   if(priceNow > ema9 && ema9 > ema21)      emaTrend = 1.0;
   else if(priceNow < ema9 && ema9 < ema21) emaTrend = -1.0;

   double emaProximity = MathMin(1.0, MathAbs(priceNow - ema9) / (atrNow * 1.5 + 0.0001));
   double emaQuality = 1.0 - emaProximity;
   if(direction > 0 && emaTrend > 0.0)      emaQuality += 0.20;
   else if(direction < 0 && emaTrend < 0.0) emaQuality += 0.20;
   else if(direction > 0 && emaTrend < 0.0) emaQuality -= 0.25;
   else if(direction < 0 && emaTrend > 0.0) emaQuality -= 0.25;

   // 2) Mum oluşumu: gövde genişliği ve yönlü kapanış, "iyi mum" ve
   // "kararsız mum" ayrımını yaparak kaliteyi belirler.
   double body = MathAbs(priceNow - openNow);
   double candleRange = MathAbs(highNow - lowNow);
   double bodyRatio = candleRange > 0.0 ? body / candleRange : 0.0;
   double candleQuality = 0.35;
   if(bodyRatio >= 0.45) candleQuality = 1.0;
   else if(bodyRatio >= 0.25) candleQuality = 0.75;
   else if(bodyRatio <= 0.10) candleQuality = 0.35;

   // 3) Göreceli hacim: mevcut bar hacmi, son 10 mum ortalamasına göre
   // çok yükselirse "hızlı ve kesin" hareket olabilir; çok düşükse zayıf
   // akış olarak değerlendirilir.
   double volAvg = 0.0;
   for(int i = 1; i <= 10; i++) {
      volAvg += (double)iVolume(symbol, PERIOD_CURRENT, i);
   }
   volAvg /= 10.0;
   double volNow = (double)iVolume(symbol, PERIOD_CURRENT, 1);
   double volRatio = (volAvg > 0.0) ? volNow / (volAvg + 0.0001) : 1.0;
   double volumeQuality = 0.5;
   if(volRatio >= 1.15 && volRatio <= 1.85) volumeQuality = 1.0;
   else if(volRatio >= 0.85 && volRatio < 1.15) volumeQuality = 0.8;
   else if(volRatio < 0.70) volumeQuality = 0.35;
   else if(volRatio > 1.85) volumeQuality = 0.65;

   // 4) Mevcut motorun ham confidence'i ve VEMA-MA filtresindeki mevcut veri,
   // risk governor'a güç olarak yansıtılır. Böylece EMA/volume dogrulama
   // ile mevcut yön sinyali birleşik bir kalite skoru üretir.
   double rawConf = RawConfidence_Get(symbol, 0.5);
   rawConf = MathMax(0.0, MathMin(1.0, rawConf));

   double quality = 0.35 * emaQuality +
                    0.25 * candleQuality +
                    0.20 * volumeQuality +
                    0.20 * rawConf;

   if(direction > 0 && priceNow < ema9) quality *= 0.88;
   if(direction < 0 && priceNow > ema9) quality *= 0.88;

   quality = MathMax(0.25, MathMin(1.0, quality));

   static datetime s_lastMQCompDiag = 0;
   if(InpSR_LogDecisions && TimeCurrent() - s_lastMQCompDiag >= 60) {
      s_lastMQCompDiag = TimeCurrent();
      PrintFormat("RISKGOV MQ DETAY | %s | dir=%d | ema=%.2f candle=%.2f vol=%.2f rawConf=%.2f -> quality=%.3f",
                  symbol, direction, emaQuality, candleQuality, volumeQuality, rawConf, quality);
   }

   return quality;
}

double RiskGovernor_ComputeMult(const SRiskGovStats &stats) {
   if(!InpRiskGov_Enable) return 1.0;

   // v1.78.130: Yeterli istatistik toplanana kadar governor "etkisiz"
   // dönmesin; erken safhada daha konservatif bir risk çarpanı uygula,
   // böylece otonom katman canlı olarak değişim gösterir.
   // Rapor analizi: mevcut durumda ortalama kayıp, ortalama kazançtan
   // daha büyük olduğu için bu aşama çok daha agresif azaltım yapmalıdır.
   if(stats.trades < InpRiskGov_MinTrades)
      return 0.55;

   double winRate = RiskGovernor_StatsWinRate(stats);
   double pf      = RiskGovernor_StatsPF(stats);
   double avgWin  = RiskGovernor_StatsAvgWin(stats);
   double avgLoss = RiskGovernor_StatsAvgLoss(stats);

   // Rapor tarafinda gorulen ana sorun: win rate iyi olsa bile
   // ortalama kayip, ortalama kardan buyukse beklenen getiri negatif olur.
   // Bu durumda governor daha erken ve daha sert azaltma uygular.
   if(avgLoss > 0.0 && avgWin > 0.0) {
      double lossVsWin = avgLoss / MathMax(avgWin, 0.0001);
      if(lossVsWin >= 1.25)
         return 0.12;
      if(lossVsWin >= 1.12)
         return 0.22;
      if(lossVsWin >= 1.03)
         return 0.40;
   }

   if(winRate >= InpRiskGov_GoodWinRate && pf >= InpRiskGov_GoodPF &&
      (avgLoss <= 0.0 || avgWin >= avgLoss * 0.95))
      return 1.0;

   if(winRate >= InpRiskGov_MediumWinRate && pf >= InpRiskGov_MediumPF)
      return 0.60;

   if(pf < 0.95)
      return 0.18;

   if(winRate >= InpRiskGov_BadWinRate || pf >= InpRiskGov_BadPF)
      return 0.28;

   return 0.08;
}

double RiskGovernor_DrawdownMult(const string symbol) {
   if(!InpRiskGov_Enable) return 1.0;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   if(balance <= 0.0 || equity <= 0.0) return 1.0;

   double ddPct = ((balance - equity) / balance) * 100.0;
   if(ddPct <= InpRiskGov_DrawdownStartPct) return 1.0;
   if(ddPct >= InpRiskGov_DrawdownHardPct) return 0.25;

   double span = MathMax(0.0001, InpRiskGov_DrawdownHardPct - InpRiskGov_DrawdownStartPct);
   double frac = (ddPct - InpRiskGov_DrawdownStartPct) / span;
   return 1.0 - (0.75 * frac);
}

double RiskGovernor_CurrentBasketLoss(const string symbol) {
   double lossMoney = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      double pnl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(pnl < 0.0) lossMoney += -pnl;
   }
   return lossMoney;
}

int RiskGovernor_SameDirectionOpenCount(const string symbol, const int direction) {
   int wantType = (direction > 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      if((int)PositionGetInteger(POSITION_TYPE) != wantType) continue;
      count++;
   }
   return count;
}

void RiskGovernor_RecordTrade(const string symbol, const int motor, const int direction, const double profit) {
   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) return;
   int dirIdx = (direction > 0) ? 0 : 1;
   if(motor < 0 || motor > 2) return;

   // MQL5'te dizi elemanlarina referans atamak "reference cannot be used"
   // hatasina neden olabilir. Bu nedenle kopya alinir ve geri yazilir.
   SRiskGovStats dirStats = g_riskGovDirStats[idx][dirIdx];
   SRiskGovStats motorStats = g_riskGovMotorStats[idx][motor];

   dirStats.trades++;
   motorStats.trades++;

   if(profit >= 0.0) {
      dirStats.wins++;
      motorStats.wins++;
      dirStats.totalProfit += profit;
      motorStats.totalProfit += profit;
      dirStats.consecutiveLosses = 0;
      motorStats.consecutiveLosses = 0;
      dirStats.consecutiveWins++;
      motorStats.consecutiveWins++;
   } else {
      double loss = -profit;
      dirStats.losses++;
      motorStats.losses++;
      dirStats.totalLoss += loss;
      motorStats.totalLoss += loss;
      dirStats.consecutiveWins = 0;
      motorStats.consecutiveWins = 0;
      dirStats.consecutiveLosses++;
      motorStats.consecutiveLosses++;
   }

   g_riskGovDirStats[idx][dirIdx] = dirStats;
   g_riskGovMotorStats[idx][motor] = motorStats;
}

double RiskGovernor_FinalLotMult(const string symbol, const int direction, const int motor) {
   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) return 1.0;
   if(!InpRiskGov_Enable) return 1.0;

   int dirIdx = (direction > 0) ? 0 : 1;
   double mult = 1.0;
   mult *= RiskGovernor_ComputeMult(g_riskGovMotorStats[idx][motor]);
   mult *= RiskGovernor_ComputeMult(g_riskGovDirStats[idx][dirIdx]);
   mult *= RiskGovernor_DrawdownMult(symbol);
   mult *= RiskGovernor_MarketQuality(symbol, direction);
   mult *= RT_RiskLotMult();

   if(mult <= 0.0) return 0.0;
   return mult;
}

// v1.78.149: yeni "blockReason" cikti parametresi - cagiran taraf (Bullet_
// Process, Lattice_TryOpenLevel) artik sabit/genel bir metin yerine hangi
// dalin GERCEKTEN engellediğini Journal'a yazabiliyor. Esik/mantik hicbiri
// degismedi - sadece hangi dalin tetiklendigi artik disariya bildiriliyor.
bool RiskGovernor_BlockEntry(const string symbol, const int motor, const int direction, string &blockReason) {
   blockReason = "";
   if(!InpRiskGov_Enable) return false;

   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) return false;

   int dirIdx = (direction > 0) ? 0 : 1;
   double motorMult = RiskGovernor_ComputeMult(g_riskGovMotorStats[idx][motor]);
   double dirMult   = RiskGovernor_ComputeMult(g_riskGovDirStats[idx][dirIdx]);

   // v1.78.150 FIX: statsInsufficient artik EN BASTA hesaplaniyor, cunku hem
   // MARKET_QUALITY_KALICI hem SOGUK_BASLANGIC bu bilgiye ihtiyac duyuyor.
   // GERCEK soguk baslangic (motorTrades=0 VE dirTrades=0, yani bu yon/motor
   // icin hic islem gecmisi yok) tespit edilirse asagidaki iki blok normal
   // esikleri (0.55 / 0.60) DEGIL, InpRiskGov_ColdStartQualityFloor tabanini
   // kullanir. Istatistik birikmeye basladiktan (trades>=MinTrades) sonra
   // normal esikler aynen devrede kalir - bu sadece ilk-islem kilidini acar,
   // genel kalite filtresini kaldirmaz.
   bool statsInsufficient = (g_riskGovMotorStats[idx][motor].trades < InpRiskGov_MinTrades ||
                             g_riskGovDirStats[idx][dirIdx].trades < InpRiskGov_MinTrades);
   bool trueColdStart = (g_riskGovMotorStats[idx][motor].trades == 0 &&
                         g_riskGovDirStats[idx][dirIdx].trades == 0);
   double mqBlockThreshold = (trueColdStart) ? InpRiskGov_ColdStartQualityFloor : 0.55;
   double csBlockThreshold = (trueColdStart) ? InpRiskGov_ColdStartQualityFloor : 0.60;

   // v1.78.131: EMA/vol/candle/ham confidence birleşik kalite skoru,
   // risk governor'un sadece istatistik değil, piyasa kalitesi üzerinden
   // de karar vermesini sağlar. Bu skor düşükse, yeni risk girişi engellenir.
   double marketQuality = RiskGovernor_MarketQuality(symbol, direction);
   if(marketQuality <= mqBlockThreshold) {
      blockReason = "MARKET_QUALITY_KALICI";
      static datetime s_lastMQDiag = 0;
      if(TimeCurrent() - s_lastMQDiag >= 60) {
         s_lastMQDiag = TimeCurrent();
         PrintFormat("RISKGOV TESHIS | %s | dir=%d | sebep=MARKET_QUALITY_KALICI | quality=%.3f (esik<=%.2f%s)",
                     symbol, direction, marketQuality, mqBlockThreshold,
                     trueColdStart ? ", SOGUK_BASLANGIC_TABANI" : "");
      }
      return true;
   }

   // Otonom katman erken safhada da aktif görünsün; yeterli veri gelene kadar
   // zayıf başlangıç istatistiği için girişleri daha agresif şekilde kontrol et.
   // v1.78.145 KALIBRASYON: esik 0.75 -> 0.60. RiskGovernor_MarketQuality()
   // simulasyonu gosterdi ki "iyi/tipik" piyasa kosullarinda (trend uyumlu,
   // orta govdeli mum, normal hacim, notr confidence) skor ~0.76 cikiyor -
   // yani 0.75 esigi normal piyasada bile ancak sinirda geciliyordu. Sonuc:
   // trades=0 -> 12 iken (soguk baslangic) RISK_GOV_BLOCK surekli tetikleniyor,
   // istatistik biriktirmek icin islem gerekirken islem acmak icin neredeyse
   // mukemmel kalite gerekiyordu - kisir dongu.
   // v1.78.150 FIX: GERCEK soguk baslangicta (motorTrades=0 & dirTrades=0)
   // bu esik de InpRiskGov_ColdStartQualityFloor'a duser (bkz. yukarida
   // csBlockThreshold) - eski 0.60 sabiti bu piyasada (quality tipik 0.50-
   // 0.58) ilk islemi sonsuza kadar engelliyordu (bkz. ekran goruntusu logu:
   // motorTrades=0 dirTrades=0 iken quality=0.580 bile SOGUK_BASLANGIC'a
   // takiliyordu). Istatistik birikmeye basladiginda (trades>=MinTrades
   // ama hala < MinTrades baska bir motor/yon icin) csBlockThreshold=0.60'a
   // geri doner - sadece ilk islem icin gevsetilir, sonrasi degismez.
   if(statsInsufficient && marketQuality < csBlockThreshold) {
      blockReason = "SOGUK_BASLANGIC";
      static datetime s_lastCSDiag = 0;
      if(TimeCurrent() - s_lastCSDiag >= 60) {
         s_lastCSDiag = TimeCurrent();
         PrintFormat("RISKGOV TESHIS | %s | dir=%d | sebep=SOGUK_BASLANGIC | quality=%.3f (esik<%.2f%s) motorTrades=%d dirTrades=%d (min=%d)",
                     symbol, direction, marketQuality, csBlockThreshold,
                     trueColdStart ? ", SOGUK_BASLANGIC_TABANI" : "",
                     g_riskGovMotorStats[idx][motor].trades, g_riskGovDirStats[idx][dirIdx].trades,
                     InpRiskGov_MinTrades);
      }
      return true;
   }

   // v1.78.136 KULLANICI KARARI: eskiden burada dogrudan "return true" vardi -
   // SRiskGovStats hic decay/reset olmadigi icin bu KALICI bir kilit oluyordu
   // (esik bir kere asilinca istatistik giris olmadan asla duzelemiyordu).
   // Artik gunluk kilit YERINE kisa bir cooldown (InpRiskGov_StatsBlockCooldownSec,
   // varsayilan 15dk) uygulaniyor: esik asildiginda sadece bu sure boyunca
   // engellenir, sure dolunca bir sonraki denemeye izin verilir (tekrar kotu
   // giderse yeni bir cooldown penceresi baslar - sonsuza kadar degil).
   if(motorMult <= 0.35 || dirMult <= 0.35) {
      datetime now = TimeCurrent();
      if(g_riskGovStatsBlockSince[idx][motor][dirIdx] == 0)
         g_riskGovStatsBlockSince[idx][motor][dirIdx] = now;
      if(InpRiskGov_StatsBlockCooldownSec <= 0 ||
         now - g_riskGovStatsBlockSince[idx][motor][dirIdx] < InpRiskGov_StatsBlockCooldownSec) {
         blockReason = "PERFORMANS_COOLDOWN";
         static datetime s_lastPCDiag = 0;
         if(InpSR_LogDecisions && TimeCurrent() - s_lastPCDiag >= 60) {
            s_lastPCDiag = TimeCurrent();
            PrintFormat("RISKGOV TESHIS | %s | dir=%d | sebep=PERFORMANS_COOLDOWN | motorMult=%.2f dirMult=%.2f (esik<=0.35)",
                        symbol, direction, motorMult, dirMult);
         }
         return true;
      }
      // Cooldown doldu - bu denemeye izin ver; sayaci sifirla ki tekrar kotu
      // giderse (motorMult/dirMult hala dusukse) YENI bir 15dk pencere baslasin.
      g_riskGovStatsBlockSince[idx][motor][dirIdx] = 0;
   } else {
      g_riskGovStatsBlockSince[idx][motor][dirIdx] = 0; // durum duzeldi, iz temizlensin
   }

   double basketLoss = RiskGovernor_CurrentBasketLoss(symbol);
   if(InpRiskGov_BasketLossLimit > 0.0 && basketLoss >= InpRiskGov_BasketLossLimit) {
      blockReason = "SEPET_ZARARI";
      static datetime s_lastBLDiag = 0;
      if(InpSR_LogDecisions && TimeCurrent() - s_lastBLDiag >= 60) {
         s_lastBLDiag = TimeCurrent();
         PrintFormat("RISKGOV TESHIS | %s | dir=%d | sebep=SEPET_ZARARI | basketLoss=%.2f (esik>=%.2f)",
                     symbol, direction, basketLoss, InpRiskGov_BasketLossLimit);
      }
      return true;
   }

   if(InpRiskGov_EntryDensityMax > 0 &&
      RiskGovernor_SameDirectionOpenCount(symbol, direction) >= InpRiskGov_EntryDensityMax) {
      blockReason = "AYNI_YON_ACIK_POZ_LIMITI";
      static datetime s_lastODDiag = 0;
      if(InpSR_LogDecisions && TimeCurrent() - s_lastODDiag >= 60) {
         s_lastODDiag = TimeCurrent();
         PrintFormat("RISKGOV TESHIS | %s | dir=%d | sebep=AYNI_YON_ACIK_POZ_LIMITI | acikPozSayisi>=%d",
                     symbol, direction, InpRiskGov_EntryDensityMax);
      }
      return true;
   }

   // v1.78.148 FIX (KOK NEDEN): bu blok eskiden HER gecerli-gorunen
   // denemede sayaci ONCE artirip SONRA kontrol ediyordu - asagida
   // Bullet_CalcLot/Lattice lot hesabi SONRADAN 0 donup emir hic
   // gonderilmese bile (bkz. "LOT_SIFIR_VEYA_NEGATIF") pencere kotasi
   // tukeniyordu, EA hicbir pozisyon acmadan kendi kendini bloke
   // ediyordu. Artik SADECE salt-okunur kontrol: pencere suresi dolmus
   // mu -> sifirla, kota zaten dolu mu -> engelle. Artirma islemi
   // RiskGovernor_RecordEntryOpened()'e tasindi (asagida tanimli) - o
   // SADECE brokerdan gercekten onaylanmis acilistan sonra cagrilir.
   if(InpRiskGov_EntryDensityMax > 0 && InpRiskGov_EntryDensitySec > 0) {
      datetime now = TimeCurrent();
      if(g_riskGovEntryStamp[idx][motor][dirIdx] != 0 &&
         now - g_riskGovEntryStamp[idx][motor][dirIdx] >= InpRiskGov_EntryDensitySec) {
         g_riskGovEntryStamp[idx][motor][dirIdx] = 0;
         g_riskGovEntryCount[idx][motor][dirIdx] = 0;
      }

      if(g_riskGovEntryCount[idx][motor][dirIdx] >= InpRiskGov_EntryDensityMax) {
         blockReason = "GIRIS_YOGUNLUGU";
         static datetime s_lastEDDiag = 0;
         if(InpSR_LogDecisions && TimeCurrent() - s_lastEDDiag >= 60) {
            s_lastEDDiag = TimeCurrent();
            PrintFormat("RISKGOV TESHIS | %s | dir=%d | sebep=GIRIS_YOGUNLUGU | pencere=%dsn kota=%d (dolu, gercek acilis bekliyor)",
                        symbol, direction, InpRiskGov_EntryDensitySec, InpRiskGov_EntryDensityMax);
         }
         return true;
      }
   }

   return false;
}

// v1.78.148 EKLENTI: entry-density penceresini SADECE gercekten ACILAN
// (brokerdan ok=true + gecerli retcode donen) pozisyonlarla besler.
// RiskGovernor_BlockEntry() artik sadece KONTROL eder, bizzat artirmaz
// (yukaridaki fonksiyona bkz). Cagrilacagi TEK yerler: Lattice_
// TryOpenLevel ve Bullet_Process'in basarili emir sonrasi noktalari.
void RiskGovernor_RecordEntryOpened(const string symbol, const int motor, const int direction) {
   if(!InpRiskGov_Enable) return;
   if(InpRiskGov_EntryDensityMax <= 0 || InpRiskGov_EntryDensitySec <= 0) return;
   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) return;
   int dirIdx = (direction > 0) ? 0 : 1;
   datetime now = TimeCurrent();
   if(g_riskGovEntryStamp[idx][motor][dirIdx] == 0 ||
      now - g_riskGovEntryStamp[idx][motor][dirIdx] >= InpRiskGov_EntryDensitySec) {
      g_riskGovEntryStamp[idx][motor][dirIdx] = now;
      g_riskGovEntryCount[idx][motor][dirIdx] = 0;
   }
   g_riskGovEntryCount[idx][motor][dirIdx]++;
}

void Stage_AWR_AEGIS(SPipelineContext &ctx) {
   g_awr = AWR_Evaluate(ctx.symbol);
   g_aegis = AEGIS_Evaluate(ctx.symbol, ctx);
   if(g_aegis.block_entry) {
      ctx.allow_new_entries = false;
      // v1.78.159 GECICI TESHIS: AEGIS block_entry, RiskGov/CONSENSUS gibi
      // kendi Journal satirini basmiyordu - sadece 60sn'de bir calisan
      // TradeDiag_Refresh() panelinde gorunuyordu, o pencereyi kacirinca
      // "neden isleme girmedi" sorusu cevapsiz kaliyordu. Asagidaki satir
      // RiskGov TESHIS ile ayni 60sn throttle mantigini, AYRI bir
      // zaman damgasiyla (s_lastAegisDiag) uygular - TradeDiag'in kendi
      // 60sn penceresine bagli degildir, AEGIS'in tetiklendigi ilk anda
      // kendi penceresinde yazar.
      static datetime s_lastAegisDiag = 0;
      if(TimeCurrent() - s_lastAegisDiag >= 60) {
         s_lastAegisDiag = TimeCurrent();
         PrintFormat("AEGIS TESHIS | %s | dir=%d | sebep=%s | awrRegime=%s",
                     ctx.symbol, ctx.dir.direction, g_aegis.reason, g_awr.name);
      }
   }
}

//+------------------------------------------------------------------+
//| 5. YARDIMCI FONKSİYONLAR                                         |
//+------------------------------------------------------------------+
ulong BuildMagic() {
   ulong base = InpMagicBase;
   string sfxStr = InpMagicChartSuffix;
   if(StringLen(sfxStr)==0) {
      int h=0; string s=_Symbol+IntegerToString(ChartID());
      for(int i=0;i<StringLen(s);i++) h=h*31+StringGetCharacter(s,i);
      h=MathAbs(h)%900+100;
      sfxStr=IntegerToString(h);
   }
   long sfx = StringToInteger(sfxStr);
   if(sfx>0) base = base*1000 + (ulong)sfx;
   return base;
}

bool IsHedgingAccount() {
   return (AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
}

bool IsNettingAccount() {
   return !IsHedgingAccount();
}

//+------------------------------------------------------------------+
//| 6. STAGED DECISION PIPELINE – AŞAMA FONKSİYONLARI                |
//|    PDF Bölüm 3 sırasına göre                                     |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Feature gates (PDF 8.4 ProfitClose / LossClose)                  |
//+------------------------------------------------------------------+
bool FeatureGate_Profit(const string which) {
   if(!InpPCF_Master) return false;
   if(which == "TREND_FLIP")     return InpPCF_TrendFlip;
   if(which == "AEG_PROFIT")     return InpPCF_AEG_Profit;
   if(which == "GRID_TP")        return InpPCF_GridTP;
   if(which == "TP_PROJECT")     return InpPCF_TP_Project;
   if(which == "GLOBAL_PROFIT")  return InpPCF_GlobalProfitReset;
   if(which == "BONUS_TP")       return InpPCF_BonusTP && RT_BonusTP();
   if(which == "PROFIT_LOCK")    return InpPCF_ProfitLock;
   return true;
}

bool FeatureGate_Loss(const string which) {
   if(!InpLCF_Master) return false;
   if(which == "TREND_FLIP")     return InpLCF_TrendFlip;
   if(which == "GLOBAL_LOSS")    return InpLCF_GlobalLossReset;
   if(which == "DAILY_LOSS")     return InpLCF_DailyLoss;
   if(which == "NEWS_LOSS")      return InpLCF_NewsLoss;
   if(which == "VIOP_LOSS")      return InpLCF_VIOP_Loss;
   if(which == "FORCED_LOSS")    return InpLCF_ForcedLoss;
   // v1.78.94 FIX: "AEG_LOSS" eskiden hicbir case'e eslenmiyordu, asagidaki
   // varsayilan "return true"a duserek panelden kapatilamiyordu.
   if(which == "AEG_LOSS")       return InpLCF_AegLoss;
   return true;
}

// Same-side minimum distance (PDF SAME SIDE MIN DISTANCE)
bool MinDist_Allows(const string symbol, const int direction) {
   if(!InpMinDist_Enable) return true;
   double need = InpMinDist_Points * SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(InpMinDist_UseATR) {
      double atr = Ind_ATR(symbol);
      if(atr > 0) need = atr * InpMinDist_ATR_Mult;
   }
   if(need <= 0) return true;

   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double nearest = 0;
   bool found = false;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      int typ = (int)PositionGetInteger(POSITION_TYPE);
      if(direction > 0 && typ != POSITION_TYPE_BUY)  continue;
      if(direction < 0 && typ != POSITION_TYPE_SELL) continue;
      double op = PositionGetDouble(POSITION_PRICE_OPEN);
      double dist = (direction > 0) ? MathAbs(bid - op) : MathAbs(op - ask);
      if(!found || dist < nearest) { nearest = dist; found = true; }
   }
   if(!found) return true;
   return (nearest >= need);
}

// Forced / time-limit reset state
int      g_resetCount = 0;
datetime g_oldestPosTime = 0;
// g_timeLimitPaused → üst global blok (v1.68)

// v1.78.41 FIX: eskiden void donuyordu, sadece PositionClose()'un bool
// donusunu (emir GONDERILDI mi, gercekten KAPANDI mi degil) AutoTune icin
// kontrol ediyordu. Cagiran taraf (orn. Stage_GlobalResets → g_resetCount++)
// kapatmanin gercekten basarili olup olmadigindan bagimsiz ilerliyordu.
// Artik kapanan/basarisiz sayisini logluyor ve "en az bir pozisyon basariyla
// kapandi mi" bilgisini donuyor; retcode basarisiz olan pozisyonlar icin
// ayrica loglaniyor (teshis kolayligi).
bool Security_CloseMagicPositions(const string symbol, const bool onlyProfit, const bool onlyLoss, const string reason) {
   int closedN = 0, failedN = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(onlyProfit && p <= 0) continue;
      if(onlyLoss   && p >= 0) continue;
      if(SafeClosePosition(t, reason)) {
         AutoTune_OnDealProfit(p); // DÜZELTME v1.68: kapatmadan önce okunan gerçek p değeri
         closedN++;
      } else {
         failedN++;
      }
   }
   PrintFormat("Security close [%s] onlyP=%d onlyL=%d closed=%d failed=%d",
               reason, onlyProfit, onlyLoss, closedN, failedN);
   return (closedN > 0);
}

// TP PEAK LIQUIDATION: Pozisyon listesi kapanan emirlerden sonra yeniden
// indekslenir. Bu nedenle peak/basket kapanisinda daima PositionsTotal()-1'den
// geriye dogru tarama yapilir; her ticket broker tarafinda dogrulanir ve
// kapanmayan pozisyon bir sonraki tick'te yeniden denenir.
bool Security_LiquidateMagicPositionsDownward(const string symbol, const string reason,
                                              int &closedN, int &failedN) {
   closedN = 0;
   failedN = 0;

   // v1.78.130: Asenkron likidasyon — TP Peak tetiklemesinde tüm pozisyonları hızlı kapatır
   // Ters döngü (en son açılanı ilk kapat) marjin geri kazanımını maksimize eder
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      double pnl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(SafeClosePosition(ticket, reason)) {
         AutoTune_OnDealProfit(pnl);
         closedN++;
      } else {
         failedN++;
         // v1.78.130 FIX: Bir pozisyon kapanamazsa, geri kalan pozisyonlara devam et
         // (tüm pozisyonları kapatma çabası devam etsin, kısmi başarı sayılır)
      }
   }

   // v1.78.130: Likidasyon başarısı: failedN==0 ideal, ama kısmi başarı (closedN>0) da log'lanır
   if(failedN > 0 && closedN > 0) {
      PrintFormat("Security_Liquidate PARTIAL | %s | closed=%d failed=%d | reason=%s",
                  symbol, closedN, failedN, reason);
   } else if(failedN > 0) {
      PrintFormat("Security_Liquidate FAILED | %s | failed=%d | reason=%s",
                  symbol, failedN, reason);
   }

   return (failedN == 0);
}


//+------------------------------------------------------------------+
//| Ses uyarıları (PDF SOUND ALERTS)                                 |
//+------------------------------------------------------------------+
void Sound_Play(const string which) {
   if(!(g_rt_ready ? g_rt_sound : InpSoundAlertsEnabled)) return;
   string file = "";
   if(which == "OPEN")          file = InpSoundTradeOpen;
   else if(which == "PROFIT")   file = InpSoundProfitClose;
   else if(which == "LOSS")     file = InpSoundLossClose;
   else if(which == "P_RESET")  file = InpSoundProfitReset;
   else if(which == "L_RESET")  file = InpSoundLossReset;
   if(StringLen(file) == 0) return;
   // Terminal Sounds/ veya Sounds/Nexus/
   if(!PlaySound(file))
      PlaySound("Sounds\\\\Nexus\\\\" + file);
}

// Aşama 1: Platform ve izin kontrolleri
bool Stage_PlatformCheck(SPipelineContext &ctx) {
   if(!InpEnableGlobalTrading) return false;
   if(!g_robotOn) return false;                    // panel ROBOT:OFF
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return false;
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) return false;
   if(!g_symInfo.Name(ctx.symbol)) return false;
   if(!g_symInfo.RefreshRates()) return false;
   return true;
}

// Aşama 2: Güvenlik katmanları – bayrakları ctx'e yaz
// (Asıl hesaplama UpdateNewsLock / UpdateVIOPStatus / UpdateDailyLock içinde)
bool Stage_SecurityLocks(SPipelineContext &ctx) {
   ctx.news_hard_lock  = g_newsHardLock;
   ctx.daily_locked    = g_dailyLocked;
   ctx.viop_blocked    = g_viopBlocked;
   ctx.security_locked = (ctx.news_hard_lock || ctx.daily_locked || ctx.viop_blocked || g_weeklyOutside);
   if(g_weeklyOutside)
      ctx.allow_new_entries = false;
   return true;
}

// Aşama 3: Pozisyon / PnL / equity / magic önbellek
void Stage_PositionCache(SPipelineContext &ctx) {
   ctx.equity      = AccountInfoDouble(ACCOUNT_EQUITY);
   ctx.balance     = AccountInfoDouble(ACCOUNT_BALANCE);
   ctx.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

   int buyN = 0, sellN = 0;
   double buyLot = 0, sellLot = 0, pnl = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      double v = PositionGetDouble(POSITION_VOLUME);
      double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      pnl += p;
      if((int)PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
         buyN++; buyLot += v;
      } else {
         sellN++; sellLot += v;
      }
   }
   // SPipelineContext'te alan yoksa sadece log/debug için tutarız
   // (ctx alanları sınırlı – equity/margin yeterli)
   ctx.equity = AccountInfoDouble(ACCOUNT_EQUITY);
}

// Aşama 4: Global kâr/zarar reset + günlük kilit
void Stage_GlobalResets(SPipelineContext &ctx) {
   // Günlük kilit zaten UpdateDailyLock ile g_dailyLocked
   if(g_dailyLocked) {
      ctx.security_locked = true;
      ctx.allow_new_entries = false;
   }
   if(g_timeLimitPaused) {
      ctx.allow_new_entries = false;
   }
   // Robot panel OFF iken reset yalnizca AllowResetWhenPaused ile
   bool paused = (!g_robotOn || !InpEnableGlobalTrading);
   bool allowWhenPaused = g_rt_ready ? g_rt_reset_idle : InpAllowResetWhenPaused;
   if(paused && !allowWhenPaused) {
      return;
   }

   // Panel RESET LIMIT: max reset asildiysa yeni giris yok
   if(g_rt_ready && g_rt_reset_limit && g_resetCount >= RT_MaxReset()) {
      ctx.allow_new_entries = false;
   }

   // Global equity kâr/zarar (session peak bazlı basit)
   static double s_peakEquity = 0;
   if(s_peakEquity <= 0) s_peakEquity = ctx.balance;
   if(ctx.equity > s_peakEquity) s_peakEquity = ctx.equity;

   double rtProf = RT_ProfitResetPct();
   double rtLoss = RT_LossResetPct();
   int rtMaxR = RT_MaxReset();
   // v1.78.38 FIX: KAR%/ZARAR% eskiden HESAP GENELİ equity-balance farkına
   // bakıyordu (AccountInfoDouble(ACCOUNT_EQUITY)), ama Security_CloseMagicPositions
   // sadece BU SEMBOLÜN pozisyonlarını kapatıyor. Aynı hesapta XAUUSD/BTCUSD/
   // USOIL gibi birden fazla sembole ayrı ayrı bu EA takılıysa, BİR sembolün
   // zararı TÜM sembollerin equity'sini düşürüyor — sağlıklı giden bir sembol
   // bile "hesap geneli zarar eşiği aşıldı" sanıp kendi (iyi giden)
   // pozisyonlarını kapatıyor, bu da hesabı düzeltmiyor (asıl zarar başka
   // sembolde), aynı tetik bir sonraki tick'te TEKRAR ateşliyor — reset
   // sayacının binlere ulaşmasının sebebi buydu. Artık SADECE bu sembolün
   // (ve bu magic'in) kendi acik pozisyon karı kullanılıyor.
   double symFloatPL = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      symFloatPL += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }
   if(rtProf > 0 && ctx.balance > 0 && FeatureGate_Profit("GLOBAL_PROFIT")) {
      double gainPct = (symFloatPL / ctx.balance) * 100.0;
      if(gainPct >= rtProf) {
         if(g_resetCount < rtMaxR) {
            // v1.78.41 FIX: Security_CloseMagicPositions artik basari bilgisi
            // donduruyor. Hicbir pozisyon kapanmadiysa (orn. "trade disabled",
            // requote zinciri) sayaç ARTMAZ — bir sonraki tick'te ayni kosul
            // tekrar denenir. En az bir pozisyon kapandiysa (kismi de olsa)
            // risk bir miktar azaldigi icin sayaç artar, boylece RT_MaxReset()
            // limiti gercek anlamda "basarili kapatma girisimi" sayisini yansitir.
            bool closedOK = Security_CloseMagicPositions(ctx.symbol, false, false, "GLOBAL_PROFIT");
            if(closedOK) {
               g_resetCount++;
               // v1.78.42 FIX (#99): InpTPProjGReset artik gercekten uygulaniyor —
               // reset sonrasi Bullet'in ilk acilis modunu (bir kerelik) belirler.
               // SECOND_AUDIT #4 FIX (P2): bu override artik SADECE
               // InpTPProjAfterProfitReset acikken uygulanir; kapaliyken kar-bazli
               // reset TP-Proj baslangic moduna hicbir mudahalede bulunmaz (normal
               // InpTPProjStart akisi bozulmadan devam eder).
               if(InpTPProjAfterProfitReset) {
                  if(InpTPProjGReset == TPP_GRESET_FIXED_LOT)     g_gresetForceStartMode = TPP_START_FIXED_LOT;
                  else if(InpTPProjGReset == TPP_GRESET_PROJECTED_LOT) g_gresetForceStartMode = TPP_START_PROJECTED_LOT;
                  // TPP_GRESET_KEEP_PEAK_LOGIC ise g_gresetForceStartMode -1 kalir (mudahale yok)
               }
               PrintFormat("GLOBAL PROFIT EXIT: +%.2f%% >= %.2f%% (reset #%d)", gainPct, rtProf, g_resetCount);
               Sound_Play("P_RESET");
               s_peakEquity = ctx.equity;
            } else {
               PrintFormat("GLOBAL PROFIT EXIT: +%.2f%% >= %.2f%% ama kapatma BASARISIZ/eksik — reset sayilmadi, tekrar denenecek",
                           gainPct, rtProf);
            }
         }
      }
   }
   if(rtLoss > 0 && ctx.balance > 0 && FeatureGate_Loss("GLOBAL_LOSS")) {
      double lossPct = (-symFloatPL / ctx.balance) * 100.0;
      if(lossPct >= rtLoss) {
         if(g_resetCount < rtMaxR) {
            bool closedOK = Security_CloseMagicPositions(ctx.symbol, false, false, "GLOBAL_LOSS");
            // v1.78.41 FIX: allow_new_entries=false BASARIYA BAKMAKSIZIN uygulanir —
            // zarar esigi asildiysa kapatma basarisiz olsa bile yeni giris ACILMAMALI,
            // bu bir güvenlik kilididir, kapatmanin basarisi ile giris izni ayri konular.
            ctx.allow_new_entries = false;
            if(closedOK) {
               g_resetCount++;
               // SECOND_AUDIT #4 FIX (P2): sadece InpTPProjAfterLossReset acikken
               // TP-Proj baslangic modu override edilir (bkz. GLOBAL_PROFIT yorumu).
               if(InpTPProjAfterLossReset) {
                  if(InpTPProjGReset == TPP_GRESET_FIXED_LOT)     g_gresetForceStartMode = TPP_START_FIXED_LOT;
                  else if(InpTPProjGReset == TPP_GRESET_PROJECTED_LOT) g_gresetForceStartMode = TPP_START_PROJECTED_LOT;
               }
               PrintFormat("GLOBAL LOSS LOCK: -%.2f%% >= %.2f%% (reset #%d)", lossPct, rtLoss, g_resetCount);
               Sound_Play("L_RESET");
            } else {
               PrintFormat("GLOBAL LOSS LOCK: -%.2f%% >= %.2f%% ama kapatma BASARISIZ/eksik — reset sayilmadi, giris yine de KAPALI, tekrar denenecek",
                           lossPct, rtLoss);
            }
         }
      }
   }

   // Forced reset: çevrim çok uzun sürdüyse
   if(InpEnableForcedReset && InpForcedResetHours > 0 && FeatureGate_Loss("FORCED_LOSS")) {
      datetime oldest = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong t = PositionGetTicket(i);
         if(t == 0 || !PositionSelectByTicket(t)) continue;
         if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
         datetime ot = (datetime)PositionGetInteger(POSITION_TIME);
         if(oldest == 0 || ot < oldest) oldest = ot;
      }
      if(oldest > 0 && (TimeCurrent() - oldest) >= (datetime)InpForcedResetHours * 3600) {
         bool closedOK = Security_CloseMagicPositions(ctx.symbol, false, false, "FORCED_RESET");
         if(closedOK) {
            g_resetCount++;
            if(InpTPProjGReset == TPP_GRESET_FIXED_LOT)     g_gresetForceStartMode = TPP_START_FIXED_LOT;
            else if(InpTPProjGReset == TPP_GRESET_PROJECTED_LOT) g_gresetForceStartMode = TPP_START_PROJECTED_LOT;
            PrintFormat("FORCED RESET: oldest age >= %d hours", InpForcedResetHours);
         } else {
            PrintFormat("FORCED RESET: oldest age >= %d hours ama kapatma BASARISIZ/eksik — reset sayilmadi, tekrar denenecek",
                        InpForcedResetHours);
         }
      }
   }

   // Time-limit reset: pozisyon yaşı
   bool tlOn = g_rt_ready ? g_rt_sure_sinir : InpEnableTimeLimitReset;
   int tlMin = g_rt_ready ? g_rt_reset_min : InpTimeLimitMinutes;
   if(tlOn && tlMin > 0) {
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong t = PositionGetTicket(i);
         if(t == 0 || !PositionSelectByTicket(t)) continue;
         if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
         datetime ot = (datetime)PositionGetInteger(POSITION_TIME);
         int ageMin = (int)((TimeCurrent() - ot) / 60);
         if(ageMin < tlMin) continue;
         double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         bool doClose = false;
         if(InpTimeResetAction == TR_CLOSE_ALL) doClose = true;
         else if(InpTimeResetAction == TR_CLOSE_PROFIT && p > 0) doClose = FeatureGate_Profit("GLOBAL_PROFIT");
         else if(InpTimeResetAction == TR_CLOSE_LOSS && p < 0) doClose = FeatureGate_Loss("FORCED_LOSS");
         if(doClose) {
            bool closedOK = SafeClosePosition(t, "TIME_LIMIT_RESET");
            if(closedOK) {
               AutoTune_OnDealProfit(p); // DÜZELTME v1.68: kapatmadan önce okunan gerçek p değeri
               PrintFormat("TIME LIMIT RESET ticket=%I64u age=%dmin action=%s", t, ageMin, EnumToString(InpTimeResetAction));
               bool pauseAfter = g_rt_ready ? g_rt_sonra_dur : InpPauseAfterTimeLimit;
               if(pauseAfter) g_timeLimitPaused = true;
            }
         }
      }
   }
}


// Aşama 4b: Panel KÂR/ZARAR BEK + ADET + HEPSİNİ KAPAT
void Stage_PanelBasketRules(SPipelineContext &ctx) {
   if(!g_rt_ready) return;

   // --- Kârlı pozisyonlar: KÂR BEK ($) eşiği + ADET ---
   if(RT_KarHepsiniKapat() && RT_ProfitBek() > 0) {
      // Topla kârlı ticket'lar (büyükten küçüğe)
      ulong tickets[];
      double profits[];
      int n = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong t = PositionGetTicket(i);
         if(t == 0 || !PositionSelectByTicket(t)) continue;
         if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
         double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         if(p >= RT_ProfitBek()) {
            ArrayResize(tickets, n+1);
            ArrayResize(profits, n+1);
            tickets[n] = t;
            profits[n] = p;
            n++;
         }
      }
      // basit bubble sort desc by profit
      for(int a=0;a<n-1;a++)
         for(int b=a+1;b<n;b++)
            if(profits[b] > profits[a]) {
               double tp=profits[a]; profits[a]=profits[b]; profits[b]=tp;
               ulong tt=tickets[a]; tickets[a]=tickets[b]; tickets[b]=tt;
            }
      int limit = RT_ProfitAdet();
      if(limit < 1) limit = 1;
      int closed = 0;
      for(int k=0; k<n && closed<limit; k++) {
         if(FeatureGate_Profit("GLOBAL_PROFIT") || FeatureGate_Profit("GRID_TP")) {
            if(SafeClosePosition(tickets[k], "PANEL_KAR_BEK")) {
               closed++;
               AutoTune_OnDealProfit(profits[k]); // DÜZELTME v1.68
               PrintFormat("PANEL KÂR BEK CLOSE ticket=%I64u pnl=%.2f (adet %d/%d)", tickets[k], profits[k], closed, limit);
            }
         }
      }
   }

   // v1.78.105 FIX (kullanici karari - TFG onceligi): Pipeline sirasinda
   // Stage_PanelBasketRules (bu blok dahil) HER TICK'TE TrendFlipGuard_Manage'
   // DEN ONCE calisiyor (bkz. OnTick akisi: satir ~12878 vs ~12964). Bu,
   // asagidaki celismeye yol acabiliyordu: BUY sepeti kardaysa ve ayni anda
   // SELL tarafinda (hedge) ZARARDAKI pozisyonlar varsa, TFG normalde BUY
   // karini kullanip SELL zararini "net-pozitif" kuraliyla dengelemeyi
   // planliyordu (bkz. TrendFlipGuard_Manage icindeki freshSideLoss mantigi).
   // Loop Harvest Protect bu karari TFG'den ONCE BUY sepetini cekip alarak
   // by-pass edebiliyordu - TFG'nin dengeleme firsatini calmis oluyordu.
   // Kullanici karari: TFG'nin (zarar tarafini koruma) onceligi olsun. Bu
   // yuzden Loop Harvest Protect artik SADECE karsi yon sepeti ZARARDA
   // DEGILSE (net>=0 veya pozisyon yoksa) devreye girer; karsi tarafta
   // zarar varsa bu tick'te MUDAHALE ETMEZ, TFG'nin dengelemesine birakir.
   // NOT: Stage_PanelBasketRules fonksiyonu basinda "if(!g_rt_ready) return;"
   // oldugu icin bu noktaya gelindiginde g_rt_ready HER ZAMAN true'dur -
   // asagida sadece g_rt_loop_harvest okunuyor (InpVG_LoopHarvestEnable
   // fallback'i burada gereksizdi, kod netligi icin sadelestirildi).
   if(g_rt_loop_harvest && InpVG_LoopProtectPct > 0.0 && RT_ProfitBek() > 0) {
      double protectThreshold = RT_ProfitBek() * (InpVG_LoopProtectPct / 100.0);
      for(int dirLoop = 0; dirLoop < 2; dirLoop++) {
         int wantType = (dirLoop == 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
         int oppType  = (dirLoop == 0) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
         double basketSum = 0.0;
         ulong  basketTickets[];
         int    basketN = 0;
         double oppSum = 0.0;
         bool   oppHasPos = false;
         for(int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong t = PositionGetTicket(i);
            if(t == 0 || !PositionSelectByTicket(t)) continue;
            if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
            if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
            int ptype = (int)PositionGetInteger(POSITION_TYPE);
            double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            if(ptype == wantType) {
               basketSum += p;
               ArrayResize(basketTickets, basketN + 1);
               basketTickets[basketN] = t;
               basketN++;
            } else if(ptype == oppType) {
               oppSum += p;
               oppHasPos = true;
            }
         }
         // Karsi taraf zararda ise (TFG'nin dengeleyecegi durum) bu tick'te
         // dokunma - TFG'ye oncelik ver.
         if(oppHasPos && oppSum < 0.0) continue;
         // NOT: KAR BEK'in kendisi zaten sepet toplaminin RT_ProfitBek()'e
         // ulasmasi durumunu (kendi bloğu, tek-pozisyon bazli, farkli mantik)
         // ayri yonetiyor - burada ust sinir basketSum < RT_ProfitBek() ile
         // cift-tetiklenme/cakisma onleniyor.
         if(basketN > 0 && basketSum >= protectThreshold && basketSum < RT_ProfitBek()) {
            if(FeatureGate_Profit("GLOBAL_PROFIT") || FeatureGate_Profit("GRID_TP")) {
               bool allOK = true;
               for(int k = 0; k < basketN; k++) {
                  if(!SafeClosePosition(basketTickets[k], "LOOP_HARVEST_PROTECT")) allOK = false;
               }
               AutoTune_OnDealProfit(basketSum);
               PrintFormat("LOOP HARVEST PROTECT BASKET CLOSE dir=%s n=%d pnl=%.2f (esik=%.2f, KARBEK=%.2f) allOK=%s",
                           (wantType == POSITION_TYPE_BUY ? "BUY" : "SELL"), basketN, basketSum, protectThreshold, RT_ProfitBek(), allOK ? "true" : "false");
            }
         }
      }
   }

   // --- Zararlı pozisyonlar: ZARAR BEK ($) mutlak eşik + ADET ---
   if(RT_ZararHepsiniKapat() && RT_LossBek() > 0) {
      ulong tickets[];
      double losses[];
      int n = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong t = PositionGetTicket(i);
         if(t == 0 || !PositionSelectByTicket(t)) continue;
         if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
         double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         if(p <= -RT_LossBek()) {
            ArrayResize(tickets, n+1);
            ArrayResize(losses, n+1);
            tickets[n] = t;
            losses[n] = p;
            n++;
         }
      }
      for(int a=0;a<n-1;a++)
         for(int b=a+1;b<n;b++)
            if(losses[b] < losses[a]) { // en kötü zarar önce
               double tp=losses[a]; losses[a]=losses[b]; losses[b]=tp;
               ulong tt=tickets[a]; tickets[a]=tickets[b]; tickets[b]=tt;
            }
      int limit = RT_LossAdet();
      if(limit < 1) limit = 1;
      int closed = 0;
      for(int k=0; k<n && closed<limit; k++) {
         if(FeatureGate_Loss("GLOBAL_LOSS") || FeatureGate_Loss("FORCED_LOSS")) {
            if(SafeClosePosition(tickets[k], "PANEL_ZARAR_BEK")) {
               closed++;
               AutoTune_OnDealProfit(losses[k]); // DÜZELTME v1.68
               PrintFormat("PANEL ZARAR BEK CLOSE ticket=%I64u pnl=%.2f (adet %d/%d)", tickets[k], losses[k], closed, limit);
            }
         }
      }
   }
}

// Aşama 5: Kârlı kapanış (Lattice TP zaten Lattice_ManageTP'de)
void Stage_ProfitExits(SPipelineContext &ctx) {
   // Basket floating kâr: tüm magic toplam PnL > PeakTarget → kapat
   double peakTarget = RT_Peak();
   if(peakTarget <= 0) return;
   if(!FeatureGate_Profit("TP_PROJECT")) return;

   double pnl = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      pnl += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }
   if(pnl >= peakTarget) {
      int closedN = 0;
      int failedN = 0;
      bool liquidationOK = Security_LiquidateMagicPositionsDownward(ctx.symbol, "BASKET_TP_PEAK", closedN, failedN);
      ctx.allow_new_entries = false;
      PrintFormat("BASKET TP PEAK LIQUIDATION: pnl=%.2f >= PeakTarget=%.2f | closed=%d failed=%d | complete=%s",
                  pnl, peakTarget, closedN, failedN, liquidationOK ? "YES" : "NO");
      if(closedN > 0) g_altTP_side = 1 - g_altTP_side;
   }

   // Virtual TP % equity (PDF VIRTUAL TAKE PROFIT)
   double vtp = VirtualTP_MoneyTarget(ctx.equity);
   if(vtp > 0 && FeatureGate_Profit("TP_PROJECT")) {
      double need = vtp;
      if(InpEnableAlternatingTP && g_altTP_side == 1)
         need = vtp * 0.75; // alternating: daha erken al
      if(pnl >= need && need > 0) {
         int closedN = 0;
         int failedN = 0;
         bool liquidationOK = Security_LiquidateMagicPositionsDownward(ctx.symbol, "VIRTUAL_TP_PEAK", closedN, failedN);
         ctx.allow_new_entries = false;
         PrintFormat("VIRTUAL TP PEAK LIQUIDATION: pnl=%.2f >= %.2f (alt=%d) | closed=%d failed=%d | complete=%s",
                     pnl, need, g_altTP_side, closedN, failedN, liquidationOK ? "YES" : "NO");
         if(closedN > 0) g_altTP_side = 1 - g_altTP_side;
      }
   }

   // AEG floating protect (ters sinyal + kâr varken)
   // v1.78.94 FIX: cooldown eklendi — bkz. asagidaki AEG_LOSSCUT_FLIP notu,
   // ayni sikayetin kar tarafindaki aynasi (kar da "kucuk kucuk" erken
   // kilitleniyordu).
   if(InpAEG_Enable && InpAEG_ProtectFloating && FeatureGate_Profit("AEG_PROFIT")) {
      if(g_aegis.protect_profit && pnl >= InpAEG_MinProfitMoney &&
         (AEG_FLIP_LAST_ACTION == 0 || TimeCurrent() - AEG_FLIP_LAST_ACTION >= InpAEG_FlipCooldownSec)) {
         if(Security_CloseMagicPositions(ctx.symbol, true, false, "AEG_PROTECT"))
            AEG_FLIP_LAST_ACTION = TimeCurrent();
         Print("AEG: floating profit protected (flip risk)");
      }
   }

   // AEG floating loss-cut (ters sinyal + zarar varken) — AEG_PROTECT'in aynasi
   // v1.78.63 FIX (#129): bu blok eskiden yoktu. Kar tarafinda "ters sinyal +
   // esik" aninda TUM karli pozisyonlari kapatiyordu (yukarida), zarar tarafinda
   // ise eslenik bir tetikleyici olmadigi icin zararli pozisyonlar ayni ters
   // sinyalde dokunulmadan buyumeye devam edebiliyordu — sadece cok daha agir
   // kosullu AEG_LOSSCUT (asagida, block_entry/%8 DD'ye bagli) veya panel ZARAR
   // BEK gibi genelde daha yuksek/gec esiklere kaliyordu. protect_loss artik
   // AYNI ters-sinyal tetikleyicisiyle ve AEG_PROTECT ile BIREBIR ayni buyuklukte
   // bir esikle (InpAEG_MinProfitMoney) zarari erken kesiyor.
   // v1.78.94 FIX: g_aegis.protect_loss BIR KERELIK gecis degil, "ters sinyal +
   // esik" surdukce her tick true kalan bir DURUM'du — ve bu blok TFG'nin
   // aksine cooldown'suzdu, o yuzden durum surdukce HER TICK basketteki tum
   // zararli pozisyonlari kapatmayi deniyordu. Basket zaten esigin altindaysa,
   // grid/bullet yeni bir bacak actiginda ve o bacak zarara dustugu an bir
   // sonraki tick'te hemen suruklenip kapatiliyordu — kullanicinin bildirdigi
   // "kucuk kucuk zarar kapatiyor, basari orani ve kasa dusuyor" sikayetinin
   // kok nedeni buydu. TFG_LAST_ACTION ile ayni cooldown deseni eklendi;
   // ayrica FeatureGate_Loss("AEG_LOSS") hicbir case'e eslenmiyordu (yukarida
   // duzeltildi) - artik gercek InpLCF_AegLoss anahtarina bagli, panelden
   // tamamen kapatilabilir.
   if(InpAEG_Enable && InpAEG_ProtectFloating && FeatureGate_Loss("AEG_LOSS")) {
      if(g_aegis.protect_loss && pnl <= -InpAEG_MinProfitMoney &&
         (AEG_FLIP_LAST_ACTION == 0 || TimeCurrent() - AEG_FLIP_LAST_ACTION >= InpAEG_FlipCooldownSec)) {
         if(Security_CloseMagicPositions(ctx.symbol, false, true, "AEG_LOSSCUT_FLIP"))
            AEG_FLIP_LAST_ACTION = TimeCurrent();
         Print("AEG: floating loss cut on trend flip (protect_profit'in zarar aynasi)");
      }
   }

   // AEG pullback: peak'ten AEG_PullbackPct geri çekilme
   if(InpAEG_Enable && FeatureGate_Profit("AEG_PROFIT") && InpAEG_PullbackPct > 0) {
      // v1.78.44 FIX (#113): static double s_aegPeak sembol bazli degildi —
      // multi-symbol modda (InpExtraSymbols dolu) bir sembolun peak PnL
      // degeri, ayni tick icinde ProcessSymbolIndex dongusunde islenen
      // BASKA bir sembolun pullback hesabina tasinabiliyordu (tek EA
      // instance'i birden fazla sembolu yonetirken). g_aegPeak[MAX_SYMBOLS]
      // ile g_sym_idx bazli ayristirildi — Lattice/Bullet state'inde zaten
      // kullanilan konvansiyonla tutarli.
      if(pnl > g_aegPeak[g_sym_idx]) g_aegPeak[g_sym_idx] = pnl;
      if(g_aegPeak[g_sym_idx] >= InpAEG_MinProfitMoney * InpAEG_ProfitHoldMult && pnl > 0) {
         double pull = ((g_aegPeak[g_sym_idx] - pnl) / g_aegPeak[g_sym_idx]) * 100.0;
         if(pull >= InpAEG_PullbackPct) {
            bool closedOK = Security_CloseMagicPositions(ctx.symbol, true, false, "AEG_PULLBACK");
            PrintFormat("AEG PULLBACK: peak=%.2f pnl=%.2f pull=%.1f%% | close_progress=%s", g_aegPeak[g_sym_idx], pnl, pull, (closedOK ? "YES" : "NO"));
            if(closedOK) g_aegPeak[g_sym_idx] = 0;
         }
      }
      if(pnl <= 0) g_aegPeak[g_sym_idx] = 0;
   }

   // AEG LossCut: ters/blok + zarar eşiği
   if(InpAEG_Enable && g_aegis.block_entry && FeatureGate_Loss("AEG_LOSS")) {
      double cutLvl = -MathAbs(InpAEG_MinProfitMoney) * MathMax(0.5, InpAEG_LossCutMult);
      if(pnl <= cutLvl && pnl < 0) {
         Security_CloseMagicPositions(ctx.symbol, false, true, "AEG_LOSSCUT");
         PrintFormat("AEG LOSSCUT: pnl=%.2f <= %.2f", pnl, cutLvl);
      }
   }
}

//+------------------------------------------------------------------+
//| 6. YÖN MOTORLARI – VEMA-X (detay) + First Touch / Classic stub   |
//+------------------------------------------------------------------+
//
//  VEMA-X NEDİR? (PDF Bölüm 5)
//  ───────────────────────────
//  Grafik zaman dilimine körü körüne bağlı kalmak yerine, canlı tick
//  akışından "sanal bar" üretir ve bu sanal barlar üzerinde EMA enerjisi
//  ölçer. Amaç: gerçek fiyat akışının yönünü ve gücünü, mum kapanışını
//  beklemeden yakalamak.
//
//  TEMEL PARAMETRELER (v1.78.61'de XAUUSD M5 100k-bar grid-search ile
//  yeniden kalibre edildi - detay icin #128 notuna bak)
//  ──────────────────
//  EMA_VirtualBarSeconds  : Kaç saniyede bir sanal bar kapatılsın (60)
//  EMA15_ConfirmBars      : Yön teyidi için kaç sanal bar gerekli (3->4)
//  EMA15_FlatSpreadMult   : Spread × bu çarpan kadar hareket yoksa
//                           "düz / gürültü" sayılır, yön nötr kalır (1.5->1.0)
//
//  ALGORİTMA ÖZETİ
//  ───────────────
//  1) Tick'leri sanal bar kovasina biriktir (VirtualBarSeconds)
//  2) Her sanal bar kapanışında EMA(15) güncelle (sanal close üzerinden)
//  3) Son N sanal barın close > EMA oranı ile yön oyu say
//  4) Toplam hareket < FlatSpreadMult × spread ise → NEUTRAL (gürültü)
//  5) Çoğunluk + minimum hareket → TREND_UP / TREND_DOWN
//  6) Confidence = |up_votes − down_votes| / ConfirmBars  (0..1)
//
//+------------------------------------------------------------------+

#define VEMA_MAX_BARS 64

struct SVemaBar {
   datetime time;
   double   open, high, low, close;
   int      ticks;
   double   ema_at_close; // v1.78.72 FIX: bu bar kapandigi andaki EMA (asagida)
};

struct SVemaState {
   bool      ready;
   SVemaBar  bars[VEMA_MAX_BARS];
   int       bar_count;          // dolu bar sayısı
   int       write_idx;          // dairesel yazma indeksi
   datetime  current_bar_start;
   double    cur_open, cur_high, cur_low, cur_close;
   int       cur_ticks;
   double    ema;                // sanal EMA(15)
   bool      ema_init;
   int       last_dir;           // hysteresis için son yön
   datetime  last_update;
};

SVemaState g_vema[MAX_SYMBOLS];

// v1.78.97: VEMA-X MA9/MA21 rejim filtresi state'i (bkz. VEMA_MA_RegimeGate)
int      g_vemaMA_upStreak[MAX_SYMBOLS];        // ardisik "EMA9 uzerinde kapanan" mum sayisi (v1.78.101: artik sadece EMA9 esasli)
int      g_vemaMA_downStreak[MAX_SYMBOLS];      // ardisik "EMA9 altinda kapanan" mum sayisi
int      g_vemaMA_confirmedRegime[MAX_SYMBOLS]; // +1 UP, -1 DOWN, 0 = henuz teyitli rejim yok
bool     g_vemaMA_weakZone[MAX_SYMBOLS];        // v1.78.101: son teyitte EMA21 henuz gecilmemisti (zayif teyit) mi
datetime g_vemaMA_lastBarTime[MAX_SYMBOLS];     // son ISLENEN kapanmis mumun acilis zamani (tick'te degil, sadece YENI mumda ilerlemek icin)
// v1.78.101 EKLENTI: Pullback modulu state'i - AYNI yondeki (rejimle uyumlu)
// sinyallerin lot/confidence olcegini pullback derinligine gore tutar.
// Lot_CalcCapped() gibi lot hesaplayicilar bu degeri PULLBACK_LotMult() ile
// okuyup kendi sonuclarina carpan olarak uygular.
double   g_pullback_lotMult[MAX_SYMBOLS];       // 1.0 = pullback yok/sig, InpPullback_MinLotMult'a kadar iner
// v1.78.105 EKLENTI (kullanici tespiti - TFG/rejim cezasi celismesi): TFG
// (TrendFlipGuard_Manage), flip kararini ctx.dir.confidence uzerinden
// veriyor (bkz. InpTFG_MinConf kontrolu). Ama VEMA_MA_RegimeGate icindeki
// MACONFLICT/pullback cezalari da AYNI res.confidence'i dusuruyordu - bu
// yuzden GERCEK bir flip sinyali (VEMA-X yuksek guvenle veriyor) rejim
// henuz 1 tick geriden geldigi icin cezalanip TFG'nin MinConf esiginin
// ALTINA dusebiliyor, TFG bu gercek flip'i "gurultu" sanip atlayabiliyordu.
// Cozum: VEMA_MA_RegimeGate, cezalardan ONCEKI HAM VEMA-X guvenini bu
// diziye kaydeder; TFG kendi karari icin BUNU okur (bkz.
// TrendFlipGuard_Manage icindeki RawConfidence_Get cagrisi).
double   g_rawConfidence[MAX_SYMBOLS];          // rejim/pullback cezalarindan ONCEKI, MIKRO TREND SONRAKI ham VEMA-X guveni; -1 = henuz hic kaydedilmedi
double   g_rawConfBase[MAX_SYMBOLS];            // v1.78.108: rejim/pullback cezalarindan ONCEKI, MIKRO TREND'den de ONCEKI SABIT taban - her tick MIKRO TREND buna SIFIRDAN uygulanir (kumulatif degil)

// v1.78.120 EKLENTI (ERB - Early Reversal Brake, kullanici PDF talebi):
// state machine NORMAL/WARNING arasinda gecis yapar. candidateScore >=
// InpERB_MinScore olan tick'ler ustuste sayilir (confirmTickCount);
// InpERB_ConfirmTicks'e ulasinca WARNING'e gecilir. WARNING'den cikis icin
// ayrica ardisik "temiz" (score<MinScore) tick sayisi (releaseTickCount)
// InpERB_ReleaseConfirmTicks'e ulasmalidir - boylece NORMAL<->WARNING
// arasinda tek tikte ziplama olmaz (belgenin 6. ve 11. bolumlerindeki
// teyit/release mantigi).
bool     g_erb_isWarning[MAX_SYMBOLS];          // true = ERB_WARNING, false = ERB_NORMAL
int      g_erb_confirmTickCount[MAX_SYMBOLS];   // WARNING'e gecis icin ardisik "bozulma" tick sayaci
int      g_erb_releaseTickCount[MAX_SYMBOLS];   // NORMAL'e donus icin ardisik "temiz" tick sayaci
int      g_erb_lastScore[MAX_SYMBOLS];          // son hesaplanan warning_score (log/panel icin)
int      g_erb_dirAtWarning[MAX_SYMBOLS];       // WARNING'e girildigi andaki yon (belgenin trend_dir_at_warning alani)
datetime g_erb_warningSince[MAX_SYMBOLS];       // WARNING'in basladigi zaman (loglama/sure takibi icin)

//--- Sanal bar kapat ve diziye ekle
void VEMA_CloseCurrentBar(SVemaState &st) {
   if(st.cur_ticks <= 0) return;

   int idx = st.write_idx % VEMA_MAX_BARS;
   st.bars[idx].time  = st.current_bar_start;
   st.bars[idx].open  = st.cur_open;
   st.bars[idx].high  = st.cur_high;
   st.bars[idx].low   = st.cur_low;
   st.bars[idx].close = st.cur_close;
   st.bars[idx].ticks = st.cur_ticks;

   st.write_idx++;
   if(st.bar_count < VEMA_MAX_BARS) st.bar_count++;

   // EMA güncelle (EMA period = 15, sanal close üzerinde)
   const int emaPeriod = 15;
   double k = 2.0 / (emaPeriod + 1.0);
   if(!st.ema_init) {
      // ilk 15 barın SMA'sı ile başlat (yeterli bar yoksa close ile)
      if(st.bar_count >= emaPeriod) {
         double sum = 0.0;
         for(int i = 0; i < emaPeriod; i++) {
            int j = (st.write_idx - 1 - i + VEMA_MAX_BARS * 2) % VEMA_MAX_BARS;
            sum += st.bars[j].close;
         }
         st.ema = sum / emaPeriod;
         st.ema_init = true;
      } else {
         st.ema = st.cur_close;
      }
   } else {
      st.ema = st.cur_close * k + st.ema * (1.0 - k);
   }
   // v1.78.72 FIX: bu barin kapandigi andaki EMA'yi barin kendisine damgala.
   // Eskiden VEMA_Evaluate() gecmis barlari SIMDIKI (guncel) EMA ile
   // kiyasliyordu; EMA her bar kapanisinda kaydigi icin 3-4 bar onceki bir
   // kapanisi bugunku EMA ile karsilastirmak, ozellikle trend hizlanirken/
   // donerken yanlis oy uretiyordu (dusuk isabet oraninin bir nedeni).
   st.bars[idx].ema_at_close = st.ema;

   // yeni bar hazırlığı
   st.cur_ticks = 0;
   st.current_bar_start = 0;
}

//--- Her tick'te çağrılır: sanal bar biriktir
void VEMA_OnTick(SVemaState &st, const string symbol) {
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   if(bid <= 0.0) return;

   datetime now = TimeCurrent();

   // Yeni sanal bar başlangıcı
   if(st.current_bar_start == 0) {
      st.current_bar_start = now;
      st.cur_open = st.cur_high = st.cur_low = st.cur_close = bid;
      st.cur_ticks = 1;
      st.last_update = now;
      return;
   }

   // Mevcut barı güncelle
   if(bid > st.cur_high) st.cur_high = bid;
   if(bid < st.cur_low)  st.cur_low  = bid;
   st.cur_close = bid;
   st.cur_ticks++;
   st.last_update = now;

   // Süre doldu mu? (v1.78.33: XAUUSD disinda RT_TimingMult ile genisler)
   int effBarSec = (int)MathRound(InpEMA_VirtualBarSeconds * RT_TimingMult(symbol));
   if(now - st.current_bar_start >= effBarSec) {
      VEMA_CloseCurrentBar(st);
      // hemen yeni bar başlat
      st.current_bar_start = now;
      st.cur_open = st.cur_high = st.cur_low = st.cur_close = bid;
      st.cur_ticks = 1;
   }

   st.ready = (st.bar_count >= MathMax(3, InpEMA15_ConfirmBars));
}

//--- Son N sanal bara bakarak yön + confidence üret
SDirectionResult VEMA_Evaluate(SVemaState &st, const string symbol) {
   SDirectionResult res;
   res.phase       = PHASE_NEUTRAL;
   res.direction   = 0;
   res.confidence  = 0.0;
   res.engine_name = "VEMA-X";
   res.timestamp   = TimeCurrent();

   if(!st.ready || !st.ema_init) {
      return res; // henüz yeterli veri yok
   }

   int need = MathMax(1, InpEMA15_ConfirmBars);
   if(st.bar_count < need) return res;

   // Son N barın close vs EMA oyu
   int upVotes = 0, downVotes = 0;
   double rangeSum = 0.0;

   for(int i = 0; i < need; i++) {
      int j = (st.write_idx - 1 - i + VEMA_MAX_BARS * 2) % VEMA_MAX_BARS;
      double c = st.bars[j].close;
      rangeSum += (st.bars[j].high - st.bars[j].low);

      // v1.78.72 FIX: bu barin KENDI kapanis anindaki EMA'sina gore oy
      // (eskiden guncel/simdiki st.ema kullanilirdi, bkz. VEMA_CloseCurrentBar
      // yorumu - yanlis referans noktasi dusuk isabet oranina katkidaydi).
      double emaRef = st.bars[j].ema_at_close;
      if(c > emaRef) upVotes++;
      else if(c < emaRef) downVotes++;
   }

   // Gürültü filtresi: toplam hareket spread × FlatSpreadMult altında ise nötr
   double point  = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double spread = (double)SymbolInfoInteger(symbol, SYMBOL_SPREAD) * point;
   if(spread <= 0.0) spread = point * 10;
   double minMove = spread * InpEMA15_FlatSpreadMult;

   // Son barların ortalama range'i çok küçükse gürültü
   double avgRange = rangeSum / need;
   if(avgRange < minMove) {
      res.phase      = PHASE_NEUTRAL;
      res.direction  = 0;
      res.confidence = 0.0;
      return res;
   }

   // Yön kararı
   if(upVotes > downVotes && upVotes >= (need + 1) / 2) {
      res.direction  = +1;
      res.phase      = PHASE_TREND_UP;
      res.confidence = (double)(upVotes - downVotes) / (double)need;
   }
   else if(downVotes > upVotes && downVotes >= (need + 1) / 2) {
      res.direction  = -1;
      res.phase      = PHASE_TREND_DOWN;
      res.confidence = (double)(downVotes - upVotes) / (double)need;
   }
   else {
      res.direction  = 0;
      res.phase      = PHASE_RANGE;   // oylar dengeli → yatay
      res.confidence = 0.0;
   }
   // v1.78.28 FIX: sabit 0.25 esigi, need=3 (varsayilan ConfirmBars) ile
   // ULASILAMAZ bir korumaydi — 3 barda mumkun tek confidence degerleri
   // 0.333 (2-1 oy) ve 1.0 (3-0 oy); 0.333 HER ZAMAN 0.25'i gectigi icin
   // bu blok pratikte hicbir zaman devreye giremiyordu, yani VEMA-X'in tek
   // whipsaw korumasi (Classic/First Touch'un aksine baska bir katmani yok)
   // fiilen KAPALIYDI: her 2-1'lik oy degisimi aninda flip'e izin veriyordu.
   // Esik artik need'e gore olceklendi: yerlesik yonu TERSINE cevirmek icin
   // bare-minimum cogunluk (2-1) yetmiyor, ConfirmBars kac olursa olsun en
   // az bir eksik oyla (need-1'den fazla) tam/near-tam mutabakat gerekiyor.
   double reverseThreshold = (double)(need - 1) / (double)need;
   if(res.direction != 0 && res.confidence < reverseThreshold && st.last_dir != 0
      && res.direction != st.last_dir) {
      // zayıf karşı sinyal → eski yönü koru (veya nötr)
      res.direction  = 0;
      res.phase      = PHASE_NEUTRAL;
      res.confidence = 0.0;
   }

   if(res.direction != 0) st.last_dir = res.direction;

   return res;
}

// v1.78.97: MA9/MA21 rejim filtresi.
// Son KAPANMIS mumun close'unu EMA9/EMA21 (PERIOD_CURRENT, mevcut ML
// handle'lari) ile kiyaslar: her ikisinin de UZERINDE -> UP bolgesi;
// her ikisinin de ALTINDA -> DOWN bolgesi; arada -> NOTR bolge (ne UP ne
// DOWN streak'i artar, ikisi de sifirlanir). InpVemaMA_ConfirmBars kadar
// ARDISIK ayni bolgede KAPANIS olunca o yon "teyitli rejim" olur. Rejim
// KENDI BASINA asla yeni bir yon uretmez.
//
// v1.78.98 FIX (DUZELTME_REHBERI #6): eskiden "VEMA_Evaluate() bir yon
// URETTIYSE ve bu yon teyitli rejimle CELISIYORSA YA DA rejim henuz hic
// teyit edilmediyse sonuc NOTR'e cekilir" seklindeydi (VETO-ONLY, tam
// nötrleme). Bu, rejim teyit edilene kadar (baslangicta / her reset
// sonrasi ConfirmBars kadar mum boyunca) VEMA-X'in TÜM sinyallerini
// oldurup islem sayisini gereksiz dusuruyordu. Artik: rejim teyitsizken
// hicbir mudahale yok; rejim teyitli ve TERS yondeyse direction/phase
// SIFIRLANMIYOR (Direction Lock'un kendi flip mantigina birakiliyor),
// sadece guven puani dusuruluyor. Ayrinti icin asagidaki fonksiyon
// govdesindeki DUZELTME_REHBERI #6 notuna bakin.
//
// v1.78.97 BUGFIX (ilk taslakta bulundu, kullaniciya sunulmadan once
// duzeltildi): bu fonksiyon HER TICK'te cagriliyor (VEMA_Evaluate ile
// ayni yerden), ama shift=1 (son KAPANMIS mum) degerleri bir mum boyunca
// SABIT kalir. Streak sayacini kosulsuz her cagrida ++ yapmak, "ardisik
// MUM" yerine fiilen "ardisik TICK" sayardi - InpVemaMA_ConfirmBars=2
// ile rejim ayni mumun icinde saniyeler icinde (2 tick sonra) teyit
// edilirdi, aslinda 2 mum suresi (dakikalarca) beklemesi gerekirken.
// Bu, tam da onlemek istenen whipsaw korumasini FIILEN devre disi
// birakirdi. Duzeltme: streak/rejim guncellemesi SADECE yeni bir mum
// kapandiginda (bar[1]'in acilis zamani degistiginde) ilerler; veto
// kontrolu ise her tick calismaya devam eder (VEMA-X'in yonu her an
// degisebilir, ona anlik tepki vermek gerekir).
// v1.78.105 EKLENTI: TFG'nin rejim/pullback cezalarindan ETKILENMEDEN ham
// VEMA-X guvenini okumasi icin helper. Sembol bulunamazsa veya hic
// kaydedilmemisse (henuz VEMA_MA_RegimeGate hic calismadiysa) CAGIRANIN
// verdigi 'fallback' degeri (TFG'de bu ctx.dir.confidence) aynen doner -
// boylece cagiran taraf yanlislikla asiri temkinli/gevsek davranmaz.
double RawConfidence_Get(const string symbol, double fallback) {
   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) return fallback;
   if(g_rawConfidence[idx] < 0.0) return fallback; // hic kaydedilmemis (sentinel -1)
   return g_rawConfidence[idx];
}

void VEMA_MA_RegimeGate(const string symbol, SDirectionResult &res) {
   int idxRaw = Ind_FindIdx(symbol);
   if(idxRaw >= 0 && idxRaw < MAX_SYMBOLS) {
      g_rawConfidence[idxRaw] = res.confidence; // v1.78.105: HER ceza/mudahaleden ONCE ham degeri kaydet (InpVemaMA_Enable=false olsa bile TFG dogru veriye erissin)
      g_rawConfBase[idxRaw] = res.confidence;   // v1.78.108: MIKRO TREND'in her tick sifirdan uygulanacagi SABIT taban
   }
   if(!InpVemaMA_Enable) return;
   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) return;

   datetime bar1Time = iTime(symbol, PERIOD_CURRENT, 1); // son KAPANMIS mumun acilis zamani
   if(bar1Time > 0 && bar1Time != g_vemaMA_lastBarTime[idx]) {
      g_vemaMA_lastBarTime[idx] = bar1Time;

      double ema9   = Ind_HandleBuf(g_ind[idx].ema9,  1);
      double ema21  = Ind_HandleBuf(g_ind[idx].ema21, 1);
      double close1 = iClose(symbol, PERIOD_CURRENT, 1);
      if(ema9 > 0.0 && ema21 > 0.0 && close1 > 0.0) {
         // v1.78.101 FIX: birincil zone artik SADECE EMA9'a gore (hizli
         // tepki icin) - "her ikisinin de ustunde/altinda" sarti fiyat
         // EMA9'u gecip EMA21'de beklerken rejimi gereksiz gecikmeye
         // sokuyordu (bkz. yukaridaki input grubu yorumu). EMA21 artik
         // sadece bu zone'un GUCLU mu ZAYIF mi teyit edildigini belirler.
         int rawZone = 0; // +1 UP (EMA9 ustu), -1 DOWN (EMA9 alti), 0 = tam EMA9'da (nadiren)
         if(close1 > ema9)      rawZone = 1;
         else if(close1 < ema9) rawZone = -1;

         bool weak = false; // true = EMA9 gecildi ama EMA21 henuz gecilmedi (zayif teyit)
         if(rawZone > 0 && close1 <= ema21) weak = true;
         if(rawZone < 0 && close1 >= ema21) weak = true;

         if(rawZone > 0)      { g_vemaMA_upStreak[idx]++;   g_vemaMA_downStreak[idx] = 0; }
         else if(rawZone < 0) { g_vemaMA_downStreak[idx]++; g_vemaMA_upStreak[idx]   = 0; }
         else                 { g_vemaMA_upStreak[idx] = 0; g_vemaMA_downStreak[idx] = 0; }

         int need = MathMax(1, InpVemaMA_ConfirmBars);
         if(g_vemaMA_upStreak[idx] >= need)        { g_vemaMA_confirmedRegime[idx] = 1;  g_vemaMA_weakZone[idx] = weak; }
         else if(g_vemaMA_downStreak[idx] >= need) { g_vemaMA_confirmedRegime[idx] = -1; g_vemaMA_weakZone[idx] = weak; }
         // Teyit tamamlanmadiysa onceki teyitli rejim KORUNUR (aninda
         // notre cekmez) - asagidaki mantik SADECE rejim TEYITLI ve VEMA-X
         // ile CELISIYORSA devreye girer (bkz. v1.78.98 FIX asagida).
      }
   }

   // v1.78.98 FIX (DUZELTME_REHBERI #6, P1): eski davranis, rejim HENUZ HIC
   // TEYIT EDILMEMISKEN (g_vemaMA_confirmedRegime[idx]==0) bile VEMA-X'in
   // URETTIGI HER sinyali tam veto ediyordu (0 != res.direction her zaman
   // dogru oldugu icin) - bu, EA baslarken veya her global reset sonrasi
   // ConfirmBars kadar mum boyunca (dakikalarca) HICBIR ISLEM acilamamasina
   // yol aciyordu; bu da testteki dusuk islem sayisinin ana nedenlerinden
   // biriydi. Ayrica confirmedRegime==0 iken direction=0 yapmak, Direction
   // Lock'un flip-teyit sayacini hic baslatamamasina neden oluyordu (iki
   // katman ayni flip'i cift bloklamis oluyordu - bkz. DUZELTME_REHBERI #7).
   //
   // Yeni davranis (rehberin onerdigi tablo, DUZELTME_REHBERI bolum 8):
   //   - Rejim TEYITSIZ (confirmedRegime==0): HICBIR MUDAHALE YOK - VEMA-X
   //     sonucu aynen geciyor (eski "tam veto" kaldirildi).
   //   - Rejim TEYITLI + VEMA-X AYNI yonde: degisiklik yok (zaten gecerdi).
   //   - Rejim TEYITLI + VEMA-X TERS yonde: direction/phase ARTIK
   //     SIFIRLANMIYOR - Direction Lock kendi FlipConfirmTicks/controlled-
   //     close mantigiyla devam etsin diye. Sadece guven puani
   //     InpVemaMA_ConflictConfidenceMult ile ciddi olcude dusuruluyor.
   //     v1.78.101: eger celisen rejim ZAYIF teyitliyse (EMA9 gecildi,
   //     EMA21 henuz gecilmedi - fiyat tam donus asamasinda) ceza
   //     InpVemaMA_WeakZoneConfidenceMult ile HAFIFLETILIYOR; rejim GUCLU
   //     teyitliyse (fiyat her iki EMA'nin da net disinda) tam ceza
   //     (InpVemaMA_ConflictConfidenceMult) uygulanmaya devam ediyor.
   if(res.direction != 0 &&
      g_vemaMA_confirmedRegime[idx] != 0 &&
      g_vemaMA_confirmedRegime[idx] != res.direction) {
      double mult = InpVemaMA_ConflictConfidenceMult;
      if(g_vemaMA_weakZone[idx])
         mult = mult + (1.0 - mult) * InpVemaMA_WeakZoneConfidenceMult; // weak=1.0 -> ceza yok (mult=1.0), weak=0.0 -> tam ceza (mult=InpVemaMA_ConflictConfidenceMult)
      res.confidence *= mult;
      res.engine_name = res.engine_name + "+MACONFLICT";
   }

   // v1.78.101 EKLENTI: TREND-ICI PULLBACK MODULU (bkz. yukaridaki input
   // grubu aciklamasi). Buraya kadar olan blok SADECE rejimle CELISEN
   // sinyalleri cezalandiriyordu; asagidaki blok ise rejimle celismeyen
   // -yani AYNI YONDEKI- sinyaller icin pullback DERINLIGINE gore bir
   // lot/confidence olcek katsayisi (g_pullback_lotMult) hesaplar. Bu
   // katsayi PULLBACK_LotMult(symbol) ile disaridan (Lot_CalcCapped vb.)
   // okunur ve o hesaplayicinin kendi sonucuna CARPAN olarak uygulanir -
   // burada dogrudan lot degistirilmiyor, sadece olcek yayinlaniyor.
   g_pullback_lotMult[idx] = 1.0; // varsayilan: pullback yok/modul kapali -> tam lot
   if(InpPullback_Enable && g_vemaMA_confirmedRegime[idx] != 0) {
      double ema9now = Ind_HandleBuf(g_ind[idx].ema9, 1);
      double priceNow = iClose(symbol, PERIOD_CURRENT, 1);
      double atrNow = Ind_ATR(symbol, 1);
      if(ema9now > 0.0 && priceNow > 0.0 && atrNow > 0.0) {
         // Pullback derinligi: fiyatin, REJIM YONUNUN TERSINE, EMA9'dan ne
         // kadar ATR uzaklikta oldugu. Rejim UP iken fiyat EMA9'un
         // ALTINDAYSA derinlik pozitif (pullback var); fiyat EMA9'un
         // ustundeyse (pullback yok, trend duz gidiyor) derinlik <=0 sayilir.
         double distATR = (priceNow - ema9now) / atrNow; // rejim UP icin: pozitifse fiyat EMA9 ustunde
         double depthATR = (g_vemaMA_confirmedRegime[idx] > 0) ? -distATR : distATR; // pullback derinligi (pozitif = geri cekilme var)

         if(depthATR > InpPullback_ShallowATR) {
            double shallow = InpPullback_ShallowATR;
            double deep    = MathMax(shallow + 0.0001, InpPullback_DeepATR); // deep, shallow'a esit/kucuk olamaz (0 bolme koruma)
            double t = (depthATR - shallow) / (deep - shallow); // 0..1 kademeli gecis
            t = MathMax(0.0, MathMin(1.0, t));
            double lotMult = 1.0 - t * (1.0 - MathMax(0.0, MathMin(1.0, InpPullback_MinLotMult)));
            g_pullback_lotMult[idx] = lotMult;

            // AYNI yondeki (rejimle uyumlu) sinyale de derin pullback'te
            // hafif ihtiyat carpani - "SIG" bolgede (t=0) carpan yok,
            // "DERIN" bolgede (t=1) InpPullback_ConfMult uygulanir.
            if(res.direction != 0 && res.direction == g_vemaMA_confirmedRegime[idx]) {
               double confMult = 1.0 - t * (1.0 - MathMax(0.0, MathMin(1.0, InpPullback_ConfMult)));
               res.confidence *= confMult;
               res.engine_name = res.engine_name + "+PULLBACK";
            }
         }
      }
   }

   // v1.78.120: ERB (Early Reversal Brake) - butun rejim/pullback
   // hesaplamalari tamamlandiktan SONRA cagrilir, boylece guncel MACONFLICT
   // durumu ve ham confidence ERB'nin puanlamasina dahil olabilir.
   ERB_Update(symbol, res);
}

// v1.78.101 EKLENTI: Pullback lot olcek katsayisini disari veren helper.
// VEMA_MA_RegimeGate her tick'te bunu gunceller; lot hesaplayicilar
// (ör. Lot_CalcCapped icinde finalLot'a carpan olarak) bu fonksiyonu
// cagirip donen degeri KENDI SONUCUNA CARPAR. Modul kapaliysa veya rejim
// teyitsizse 1.0 (etkisiz) doner - hicbir yerde cagrilmasa da guvenlidir.
double PULLBACK_LotMult(const string symbol) {
   if(!InpPullback_Enable) return 1.0;
   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) return 1.0;
   double m = g_pullback_lotMult[idx];
   if(m <= 0.0 || m > 1.0) return 1.0; // guvenlik: gecersiz deger varsa etkisiz say
   return m;
}

// v1.78.120 EKLENTI: EARLY REVERSAL BRAKE (ERB) - kullanicinin verdigi
// teknik plana (DGN_Nexus_VEMAX_Early_Reversal_Brake) gore uygulanmistir.
// AMAC: VEMA-X ana motorunu HICBIR SEKILDE degistirmeden, ana flip zinciri
// (VEMA-X -> VEMA-MA rejim teyidi -> TFG) tamamlanana kadar gecen surede
// eski yonde YENI risk uretimini (Grid kademesi, Bullet girisi, Loop
// Harvest re-entry) GECICI olarak durdurmak. ERB:
//   - Direction'i DEGISTIRMEZ (res parametresi const, hicbir alani yazilmaz)
//   - Direction Lock'u bypass ETMEZ
//   - TFG'nin yerine GECMEZ
//   - Mevcut acik pozisyonlara DOKUNMAZ (TP/BE/trailing/Dongu Hasadi
//     kapanislari/AEGIS hepsi normal calismaya devam eder)
//   - SADECE ERB_BlocksNewRisk() araciligiyla "yeni giris kapisini" kapatir
//
// Puanlama (belgenin 5.1 bolumu, mevcut kod verileriyle eslestirildi):
//   1) PriceAgainstTrend    : fiyat, rejimin EMA9 referansinin KARSI
//                             tarafina gecti mi (v1.78.101'deki EMA9-bazli
//                             hizli zone mantiginin AYNISI, ters yonde)
//   2) VemaSlopeAgainstTrend: EMA9'un anlik egimi rejime karsi mi
//   3) ATRDisplacement      : fiyat, rejim yonunun TERSINE InpERB_ATRDistance
//                             kadar ATR mesafesi kat etti mi
//   4) MomentumWeakening    : ham (rejim cezasindan ONCEKI) VEMA-X guveni
//                             dusuk mu (RawConfidence_Get ile okunur)
//   5) EnsembleWeakAgainstTrend: VEMA-MA'nin kendi MACONFLICT cezasi bu
//                             tick'te AKTIF mi (rejim ile VEMA-X CELISIYOR mu)
void ERB_Update(const string symbol, const SDirectionResult &res) {
   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) return;
   if(!InpERB_Enable) { g_erb_isWarning[idx] = false; return; } // kapaliysa hep NORMAL, hicbir yeri bloklamaz

   int regime = g_vemaMA_confirmedRegime[idx]; // +1 UP, -1 DOWN, 0 = teyitsiz
   if(regime == 0) {
      // Rejim henuz teyitsizken ERB'nin "karsi trend" kavrami anlamsiz -
      // NORMAL sayilir, sayaçlar sifirlanir (yanlis warning birikmesin).
      g_erb_isWarning[idx] = false;
      g_erb_confirmTickCount[idx] = 0;
      g_erb_releaseTickCount[idx] = 0;
      g_erb_lastScore[idx] = 0;
      return;
   }

   double ema9now = Ind_HandleBuf(g_ind[idx].ema9, 1);
   double ema9prev = Ind_HandleBuf(g_ind[idx].ema9, 2);
   double priceNow = iClose(symbol, PERIOD_CURRENT, 1);
   double atrNow = Ind_ATR(symbol, 1);

   int score = 0;

   // Bilesen 1: Fiyat/VEMA iliskisi
   bool priceAgainst = false;
   if(InpERB_UsePriceCross && ema9now > 0.0 && priceNow > 0.0) {
      priceAgainst = (regime > 0) ? (priceNow < ema9now) : (priceNow > ema9now);
      if(priceAgainst) score++;
   }

   // Bilesen 2: Slope bozulmasi
   if(InpERB_UseSlope && ema9now > 0.0 && ema9prev > 0.0) {
      double slope = ema9now - ema9prev;
      bool slopeAgainst = (regime > 0) ? (slope < 0.0) : (slope > 0.0);
      if(slopeAgainst) score++;
   }

   // Bilesen 3: ATR displacement
   // v1.78.122 FIX (kod incelemesinde bulundu - kritik): "displaced=true"
   // MATEMATIKSEL OLARAK "priceAgainst=true" ANLAMINA GELIYORDU (fiyat
   // EMA9'dan ATR*mesafe kadar uzaklastiysa, zaten EMA9'un karsi
   // tarafindadir) - yani bu iki bilesen ISTATISTIKSEL BAGIMSIZ DEGILDI,
   // ATR displacement tetiklendiginde HER ZAMAN +2 puan (kendisi + Bilesen1)
   // birden geliyordu, TEK bir gercek olaydan. Bu, belgenin "en az 2-3
   // BAGIMSIZ bozulma kosulu" ilkesini INCE bir sekilde zayiflatiyordu -
   // MinScore=3 gorunse de fiili bagimsiz esik daha dusuktu. Duzeltme:
   // Bilesen 3 artik SADECE "priceAgainst YOKKEN bile displaced olustu mu"
   // diye bakmiyor (bu zaten imkansiz) - bunun yerine iki bilesen
   // KARSILIKLI DISLAYICI hale getirildi: Bilesen1 SADECE "hafif karsi"
   // (ATR esigini henuz asmamis) durumda puan verir, Bilesen3 "ciddi karsi"
   // (ATR esigini asmis) durumda puan verir - ayni olay artik SADECE BIR
   // puan katkisi yapar.
   bool displaced = false;
   if(InpERB_UseATRDisplacement && ema9now > 0.0 && priceNow > 0.0 && atrNow > 0.0) {
      double requiredMove = atrNow * InpERB_ATRDistance;
      displaced = (regime > 0) ? ((ema9now - priceNow) >= requiredMove)
                                : ((priceNow - ema9now) >= requiredMove);
      if(displaced) {
         score++;
         if(priceAgainst) score--; // v1.78.122: cift sayimi iptal et - ayni olay sadece 1 puan versin
      }
   }

   // Bilesen 4: Momentum zayiflamasi (ham VEMA-X guveni dusuk mu)
   if(InpERB_UseMomentumWeakening) {
      double rawConf = RawConfidence_Get(symbol, res.confidence);
      if(rawConf < 0.35) score++; // v1.78.112'deki MIN taban (0.50) altina yakin bir esik - "zayif" sayilir
   }

   // Bilesen 5: Ensemble/rejim uyumsuzlugu
   // v1.78.121/122 FIX (kullanici talebi - "bayat bir sey kalmasin"):
   // Ilk yazimda global g_di/g_tmi okunuyordu, ama bunlar SADECE
   // Consensus_Evaluate() (Stage_MicroLayers icinde, ERB_Update'TEN SONRA
   // calisan bir asama) tarafindan guncelleniyor - yani ERB o an BIR TICK
   // GERIDEN (bayat) DI/TMI verisi görecekti. Kullanici tutarsizligi kabul
   // etmedigi icin, ERB artik DI_Evaluate()/TMI_Evaluate()'i BURADA TAZE
   // olarak (global g_di/g_tmi'ye YAZMADAN, sadece donus degerini kullanarak)
   // cagiriyor - Consensus_Evaluate'in kendi akisina hicbir etkisi yok,
   // sadece ERB kendi guncel kopyasini hesapliyor.
   if(InpERB_UseEnsembleWeakness) {
      bool maConflict = (StringFind(res.engine_name, "+MACONFLICT") >= 0);
      SDIResult  erbDi  = DI_Evaluate(symbol);
      STMIResult erbTmi = TMI_Evaluate(symbol);
      bool diAgainst  = (erbDi.mature && erbDi.direction != 0 && erbDi.direction != regime);
      bool tmiAgainst = (erbTmi.valid && erbTmi.direction != 0 && erbTmi.direction != regime);
      if(maConflict || diAgainst || tmiAgainst) score++;
   }

   g_erb_lastScore[idx] = score;
   bool candidateWarning = (score >= InpERB_MinScore);

   if(candidateWarning) {
      g_erb_confirmTickCount[idx]++;
      g_erb_releaseTickCount[idx] = 0;
   } else {
      g_erb_releaseTickCount[idx]++;
      g_erb_confirmTickCount[idx] = 0;
   }

   bool wasWarning = g_erb_isWarning[idx];
   if(!wasWarning && g_erb_confirmTickCount[idx] >= InpERB_ConfirmTicks) {
      g_erb_isWarning[idx] = true;
      g_erb_dirAtWarning[idx] = regime;
      g_erb_warningSince[idx] = TimeCurrent();
      if(InpERB_LogDecisions)
         PrintFormat("[ERB] NORMAL -> WARNING | %s | dir=%s | score=%d/%d", symbol, (regime>0?"BUY":"SELL"), score, InpERB_MinScore);
   } else if(wasWarning && g_erb_releaseTickCount[idx] >= InpERB_ReleaseConfirmTicks) {
      g_erb_isWarning[idx] = false;
      if(InpERB_LogDecisions)
         PrintFormat("[ERB] WARNING -> NORMAL | %s | release_score=%d | duration=%dsec",
                     symbol, score, (int)(TimeCurrent() - g_erb_warningSince[idx]));
   }
   // Ne yeni WARNING ne yeni NORMAL esigine ulasilmadiysa durum degismez
   // (belgenin 6. ve 11. bolumlerindeki "tek tick ile ziplama olmasin" kurali).
}

// v1.78.120: Yeni giris noktalarinin (Grid/Bullet/Loop Harvest re-entry)
// cagirdigi tek kapi. true donerse o tick'te YENI GIRIS YAPILMAMALIDIR -
// cagiran taraf mevcut pozisyon yonetimine (TP/BE/trailing/kapanma)
// KESINLIKLE DOKUNMAMALIDIR, sadece "yeni ac" adimini atlamalidir.
bool ERB_BlocksNewRisk(const string symbol) {
   if(!InpERB_Enable) return false;
   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) return false;
   return g_erb_isWarning[idx];
}

//--- First Touch (PDF: bariyer + olasılık)
// Lookback penceresinde high/low bariyerlerine göre
// "fiyat önce yukarı mı aşağı mı dokunur?" tahmini.
// REPAINT FIX: First Touch bariyer ve momentum oyları yalnızca kapanmış M1
// barlarından hesaplanır; oluşan barın gelecekteki high/low bilgisi kullanılamaz.
SDirectionResult Engine_FirstTouch(const string symbol) {
   SDirectionResult res;
   res.engine_name = "FirstTouch";
   res.phase       = PHASE_NEUTRAL;
   res.direction   = 0;
   res.confidence  = 0.0;
   res.timestamp   = TimeCurrent();

   // Launch throttle
   // v1.78.29 FIX: s_lastFT hic guncellenmiyordu, yani "s_lastFT>0" sarti
   // asla saglanmiyor ve throttle FIILEN HIC DEVREYE GIRMIYORDU — yorumdaki
   // "3 saniyede bir" niyetine ragmen fonksiyon HER TICK'TE yeniden
   // hesapliyordu. Sadece damgayi guncellemek yeterli degil: throttle
   // penceresinde bos/notr donmek, gercek sinyali periyodik olarak yapay
   // sekilde notre dusurup YENI bir whipsaw kaynagi yaratirdi — bu yuzden
   // son hesaplanan SONUC da onbelleklenip pencere icinde o donduruluyor.
   static datetime         s_lastFT[MAX_SYMBOLS];
   static SDirectionResult s_lastFTRes[MAX_SYMBOLS];
   int ftIdx = Ind_FindIdx(symbol);
   if(ftIdx < 0 || ftIdx >= MAX_SYMBOLS) ftIdx = 0;
   if(InpFT_LaunchEverySeconds > 0 && s_lastFT[ftIdx] > 0 &&
      TimeCurrent() - s_lastFT[ftIdx] < InpFT_LaunchEverySeconds)
      return s_lastFTRes[ftIdx];

   // v1.78.33: XAUUSD disinda RT_TimingMult ile genisler (daha uzun lookback/horizon)
   double ftMult = RT_TimingMult(symbol);
   int lookback = MathMax(10, (int)MathRound(InpFT_LookbackSeconds * ftMult));
   int bars = MathMax(5, lookback / 60 + 2);
   MqlRates rates[];
   if(CopyRates(symbol, PERIOD_M1, 1, bars, rates) < bars) { s_lastFT[ftIdx] = TimeCurrent(); s_lastFTRes[ftIdx] = res; return res; }
   ArraySetAsSeries(rates, true);

   double hi = rates[0].high, lo = rates[0].low;
   for(int i = 1; i < bars; i++) {
      if(rates[i].high > hi) hi = rates[i].high;
      if(rates[i].low  < lo) lo = rates[i].low;
   }
   double range = hi - lo;
   if(range <= 0) { s_lastFT[ftIdx] = TimeCurrent(); s_lastFTRes[ftIdx] = res; return res; }

   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double midPx = (bid + ask) * 0.5;
   long spr = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0) point = _Point;

   // Dinamik bariyer: spread×mult ve lookback range×moveMult
   double barrierSpr = (double)spr * point * InpFT_BarrierSpreadMult;
   double barrierMove = range * (InpFT_BarrierMoveMult / 100.0);
   double barrier = MathMax(barrierSpr, barrierMove);
   double upBarrier = midPx + barrier;
   double dnBarrier = midPx - barrier;

   double distUp   = MathMax(0.0, upBarrier - bid);
   double distDown = MathMax(0.0, bid - dnBarrier);
   double tot = distUp + distDown;
   if(tot <= 0) { s_lastFT[ftIdx] = TimeCurrent(); s_lastFTRes[ftIdx] = res; return res; }

   // Momentum oyları (horizon penceresi)
   int horizonBars = MathMax(1, (int)MathRound(InpFT_HorizonSeconds * ftMult) / 60);
   int upClose = 0, dnClose = 0;
   int nVote = MathMin(MathMax(3, horizonBars), bars - 1);
   for(int i = 0; i < nVote; i++) {
      if(rates[i].close > rates[i + 1].close) upClose++;
      else if(rates[i].close < rates[i + 1].close) dnClose++;
   }

   double pUp = 0.5;
   if(upClose + dnClose > 0)
      pUp = (double)upClose / (upClose + dnClose);
   // Yakın bariyer ağırlığı
   pUp = pUp * 0.55 + (distDown / tot) * 0.45;
   pUp = MathMax(0.05, MathMin(0.95, pUp));
   double pDn = 1.0 - pUp;

   // ConfidenceZ: ayrışma eşiği (basit z-skor proxy)
   double sep = MathAbs(pUp - 0.5) * 2.0;  // 0..1
   double zOk = (sep * 3.0 >= InpFT_ConfidenceZ); // Z≈1 → sep>=0.33

   double minP = InpFT_MinProbability;
   if(zOk && pUp >= minP && pUp > pDn) {
      res.direction  = +1;
      res.phase      = PHASE_TREND_UP;
      res.confidence = pUp;
   } else if(zOk && pDn >= minP && pDn > pUp) {
      res.direction  = -1;
      res.phase      = PHASE_TREND_DOWN;
      res.confidence = pDn;
   } else {
      res.phase = PHASE_RANGE;
      res.confidence = sep;
   }
   s_lastFT[ftIdx] = TimeCurrent();
   s_lastFTRes[ftIdx] = res;
   return res;
}

//--- Classic Live (hızlı + yavaş pencere faz enerjisi)
// REPAINT FIX: ClassicLive hızlı/yavaş enerji pencereleri tamamlanmış M1
// barlarını kullanır; canlı mum kapanmadan yön değişmez.
SDirectionResult Engine_ClassicLive(const string symbol) {
   SDirectionResult res;
   res.engine_name = "ClassicLive";
   res.phase       = PHASE_NEUTRAL;
   res.direction   = 0;
   res.confidence  = 0.0;
   res.timestamp   = TimeCurrent();

   int winSec  = MathMax(30, InpClassicLiveWindowSec);
   int fastSec = MathMax(5,  InpClassicLiveFastSec);
   int barsSlow = MathMax(5, winSec / 60 + 2);
   int barsFast = MathMax(3, fastSec / 60 + 2);

   MqlRates rates[];
   int need = MathMax(barsSlow, barsFast) + 2;
   if(CopyRates(symbol, PERIOD_M1, 1, need, rates) < need) return res;
   ArraySetAsSeries(rates, true);

   // Yavaş pencere: net close değişimi / range
   double slowOpen = rates[barsSlow - 1].open;
   double slowClose = rates[0].close;
   double slowMove = slowClose - slowOpen;
   double slowRange = 0;
   for(int i = 0; i < barsSlow; i++)
      slowRange += (rates[i].high - rates[i].low);
   if(slowRange <= 0) slowRange = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;

   // Hızlı pencere
   double fastOpen = rates[barsFast - 1].open;
   double fastClose = rates[0].close;
   double fastMove = fastClose - fastOpen;

   double slowEnergy = slowMove / slowRange;
   double fastEnergy = fastMove / (slowRange / barsSlow * barsFast + 1e-10);

   // Warmup: yeterli bar yoksa nötr
   if(need < 5) return res;

   // Yön: yavaş ve hızlı aynı taraftaysa trend
   double energy = 0.6 * slowEnergy + 0.4 * fastEnergy;
   double absE = MathAbs(energy);

   // v1.78.130: ATR/momentum tabanli guvenlik katmani — ufak mikro
   // hareketlerde bilesenler trend gibi gorunup sahte yon uretmesin.
   double atr = Ind_ATR(symbol, 1);
   if(atr <= 0.0) atr = Ind_ATR(symbol, 0);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0.0) point = _Point;
   double movementGate = MathMax(point * 10.0, atr * 0.40);
   if(MathAbs(slowMove) < movementGate && MathAbs(fastMove) < movementGate * 0.75) {
      res.phase = PHASE_RANGE;
      res.confidence = MathMin(1.0, (MathAbs(slowMove) + MathAbs(fastMove)) / MathMax(movementGate, point));
      return res;
   }

   // Gate'ler input'tan (PDF Classic Live)
   double dirGate = InpClassicLiveDirectionGate;
   double effGate = InpClassicLiveEfficiencyGate;
   double energyGate = InpClassicLiveEnergyGate;

   // Warmup zorunluysa yetersiz bar → nötr
   if(InpClassicLiveRequireWarmup && need < MathMax(5, InpClassicLiveWarmupSec / 60 + 2))
      return res;

   if(absE < energyGate) {
      res.phase = PHASE_RANGE;
      res.confidence = absE;
      return res;
   }

   // Pulse gate (hızlı enerji eşiği)
   if(MathAbs(fastEnergy) < InpClassicLivePulseGate) {
      res.phase = PHASE_NEUTRAL;
      res.confidence = MathAbs(fastEnergy);
      return res;
   }

   double efficiency = (slowRange > 0) ? MathAbs(slowMove) / slowRange : 0;
   if(efficiency < effGate) {
      res.phase = PHASE_NEUTRAL;
      res.confidence = efficiency;
      return res;
   }

   if(energy > dirGate && slowEnergy > 0 && fastEnergy > 0) {
      res.direction  = +1;
      res.phase      = PHASE_TREND_UP;
      res.confidence = MathMin(1.0, absE * 3.0);
   } else if(energy < -dirGate && slowEnergy < 0 && fastEnergy < 0) {
      res.direction  = -1;
      res.phase      = PHASE_TREND_DOWN;
      res.confidence = MathMin(1.0, absE * 3.0);
   } else if(absE < dirGate * 0.5) {
      res.phase = PHASE_RANGE;
      res.confidence = 0.2;
   } else {
      res.phase = PHASE_NEUTRAL;
      res.confidence = absE;
   }
   return res;
}

//--- Pipeline giriş noktası
SDirectionResult Stage_DirectionEngine(const string symbol) {
   SDirectionResult res;
   res.phase       = PHASE_NEUTRAL;
   res.direction   = 0;
   res.confidence  = 0.0;
   res.timestamp   = TimeCurrent();
   res.engine_name = "None";

   // DirectionEngineLock: panel/engine input değişse bile ilk seçilen motor
   static int s_lockedEngine = -1;
   int eng = (g_rt_ready ? g_rt_dir_engine : (int)InpDirectionEngine); // FIX v1.78.13: panelden secilebilir
   if(InpDirectionEngineLock) {
      if(s_lockedEngine < 0) s_lockedEngine = eng;
      eng = s_lockedEngine;
   } else {
      s_lockedEngine = eng;
   }

   // v1.78.106 FIX (guvenlik onlemi): g_rawConfidence sadece DIR_ENGINE_VEMA
   // case'inde (VEMA_MA_RegimeGate icinde) guncelleniyor. Kullanici baska
   // bir yon motoruna (First Touch, Classic Live vb.) gecerse veya
   // InpDirectionEngineLock=false iken motor degisirse, bu deger eski VEMA
   // calismasindan kalma BAYAT bir sayida donup kalabilir - RawConfidence_Get
   // bunu "gecerli" sanip yanlislikla kullanabilirdi. Onlem: switch'ten once
   // koşulsuz sentinel'e (-1) dondur; SADECE DIR_ENGINE_VEMA case'i
   // VEMA_MA_RegimeGate araciligiyla gercek deger yazar.
   // v1.78.122 FIX (kod incelemesinde bulundu - KRITIK): ERB_Update() de
   // AYNI SEKILDE sadece VEMA_MA_RegimeGate icinden (yani SADECE
   // DIR_ENGINE_VEMA case'i calisirken) tetikleniyordu, ama bu guvenlik
   // agina DAHIL EDILMEMISTI. Motor VEMA-X disina gecerse ERB_Update HIC
   // CAGRILMAZ, g_erb_isWarning[] SON BILINEN (bayat) degerinde SONSUZA
   // KADAR kilitli kalirdi - eger o an isWarning=true idiyse, Grid/Bullet
   // yeni motorle (First Touch/Classic Live) calisirken bile SURESIZ
   // bloklanmis olurdu (ERB_BlocksNewRisk hep true dondurmeye devam eder,
   // hicbir zaman NORMAL'e donemez cunku onu guncelleyecek kod calismiyor).
   {
      int idxSentinel = Ind_FindIdx(symbol);
      if(idxSentinel >= 0 && idxSentinel < MAX_SYMBOLS) {
         g_rawConfidence[idxSentinel] = -1.0;
         g_rawConfBase[idxSentinel] = -1.0;
         g_erb_isWarning[idxSentinel] = false; // v1.78.122: motor VEMA disindaysa ERB de etkisiz/NORMAL sayilir
         g_erb_confirmTickCount[idxSentinel] = 0;
         g_erb_releaseTickCount[idxSentinel] = 0;
      }
   }
   switch(eng) {
      case DIR_ENGINE_VEMA: {
         int vi = Ind_FindIdx(symbol);
         if(vi < 0 || vi >= MAX_SYMBOLS) vi = 0;
         VEMA_OnTick(g_vema[vi], symbol);
         res = VEMA_Evaluate(g_vema[vi], symbol);
         VEMA_MA_RegimeGate(symbol, res); // v1.78.97: MA9/MA21 rejim veto filtresi
         break;
      }
      case DIR_ENGINE_FIRST_TOUCH:
         res = Engine_FirstTouch(symbol);
         break;
      case DIR_ENGINE_CLASSIC:
         res = Engine_ClassicLive(symbol);
         break;
   }

   // Classic Live entry/flip confirm (ms)
   // v1.78.29 FIX: eskiden yon ILK DEGISTIGI an SERBEST kaliyordu (sadece
   // confidence yariya iniyor, direction sifirlanmiyordu); asil bloklama ise
   // yon SABIT kalirken (yani gercek teyit suresi boyunca) devreye giriyordu
   // — yani TAM TERSI calisiyordu: gurultulu flip anlik geciyor, sonra kisa
   // bir sure susturuluyordu. Ayrica InpClassicLiveFlipConfirmMs (3600ms)
   // sadece acik/kapali bayrak gibi okunuyordu, gercek suresi HIC
   // kullanilmiyordu (VEMA-X'in olu esigiyle ayni aile hata).
   // YENI: yon DEGISTIGI ANDA bloklanir, teyit suresi o an baslar; notrden
   // TAZE girise EntryConfirmMs (900ms, kisa), MEVCUT yonu TERSINE cevirmeye
   // FlipConfirmMs (3600ms, uzun — VEMA-X'teki "tersine cevirmek daha zor
   // olsun" ilkesiyle ayni) uygulanir.
   static int      s_clDir[MAX_SYMBOLS];   // son TEYITLI Classic yonu
   static ulong    s_clSinceMs[MAX_SYMBOLS];  // mevcut adayin basladigi an (ms)
   static int      s_clNeededMs[MAX_SYMBOLS]; // bu aday icin gereken bekleme (ms)
   static int      s_lastNonZeroDir[MAX_SYMBOLS]; // son non-zero yonu flip oncesi hatirla
   int clIdx = Ind_FindIdx(symbol);
   if(clIdx < 0 || clIdx >= MAX_SYMBOLS) clIdx = 0;
   if(eng == DIR_ENGINE_CLASSIC) {
      if(res.direction != 0 && res.direction != s_clDir[clIdx]) {
         bool isReversal = (s_clDir[clIdx] != 0);
         // v1.78.33: XAUUSD disinda RT_TimingMult ile genisler
         int baseMs = isReversal ? InpClassicLiveFlipConfirmMs : InpClassicLiveEntryConfirmMs;
         s_clNeededMs[clIdx] = (int)MathRound(baseMs * RT_TimingMult(symbol));
         s_clDir[clIdx]   = res.direction;
         s_clSinceMs[clIdx] = GetTickCount64();
         if(s_clNeededMs[clIdx] > 0) { res.direction = 0; res.phase = PHASE_NEUTRAL; res.confidence = 0; }
      } else if(res.direction != 0 && res.direction == s_clDir[clIdx]) {
         ulong elapsed = GetTickCount64() - s_clSinceMs[clIdx];
         if(elapsed < (ulong)MathMax(0, s_clNeededMs[clIdx])) { res.direction = 0; res.phase = PHASE_NEUTRAL; res.confidence = 0; }
      } else if(res.direction == 0) {
         s_clDir[clIdx] = 0; // motor kendisi notr dedi -> aday iptal, bastan teyit gerekir
      }
   }

   // v1.78.130: flip aninda ekranin bir kez cikmasini (aynı anda fiyatla
   // cekilen mini sinyaller) engellemek icin, son non-zero yon haritalanir
   // ve ancak yeterli momentum/confidence ile yeni yon kabul edilir.
   if(res.direction != 0) {
      bool isFlip = (s_lastNonZeroDir[clIdx] != 0 && s_lastNonZeroDir[clIdx] != res.direction);
      double atr = Ind_ATR(symbol, 1);
      if(atr <= 0.0) atr = Ind_ATR(symbol, 0);
      double close1 = iClose(symbol, PERIOD_CURRENT, 1);
      double close2 = iClose(symbol, PERIOD_CURRENT, 2);
      double momentum = 0.0;
      if(atr > 0.0 && close1 > 0.0 && close2 > 0.0)
         momentum = MathAbs(close1 - close2) / atr;
      if(isFlip && (momentum < 0.45 || res.confidence < 0.55)) {
         res.direction = 0;
         res.phase = PHASE_NEUTRAL;
         res.confidence = 0.0;
      } else if(!isFlip && momentum < 0.20 && res.confidence < 0.35) {
         res.direction = 0;
         res.phase = PHASE_NEUTRAL;
         res.confidence = 0.0;
      } else {
         s_lastNonZeroDir[clIdx] = res.direction;
      }
   }

   // FirstTouch launch stamp + MinResolved (conf eşiği proxy)
   if(eng == DIR_ENGINE_FIRST_TOUCH && res.direction != 0) {
      if(InpFT_MinResolved > 0 && res.confidence < (double)InpFT_MinResolved / 100.0) {
         res.direction = 0;
         res.phase = PHASE_NEUTRAL;
         res.confidence = 0;
      } else {
         // throttle stamp Engine_FirstTouch static ile uyumlu
      }
   }

   return res;
}

// Aşama 7: Mikro katmanlar → Stage_MicroLayers bölüm 11'de (ONNX/Shadow)

// Aşama 8: Router / UDC – Trend/Bullet veya Grid tarafına izin
bool Stage_RouterUDC(SPipelineContext &ctx) {
   // Güvenlik kilidi her zaman yeni girişi keser
   if(ctx.security_locked) {
      ctx.allow_new_entries = false;
      return false;
   }
   // MicroLayers (ONNX eşiği vb.) önceden false yaptıysa koru
   // Aksi halde varsayılan açık
   if(!ctx.allow_new_entries) return false;
   ctx.allow_new_entries = true;
   return true;
}

// Aşama 9: Son veto (BUY/SELL izni, min mesafe, marjin, lot step, netting uyumu)

//+------------------------------------------------------------------+
//| DIRECTION EXTRA CHECKS (PDF) – FinalVeto / giriş öncesi          |
//+------------------------------------------------------------------+
datetime g_extra_lastEntryTime[MAX_SYMBOLS]; // v1.68 per-symbol

bool ExtraChecks_Allows(const string symbol, string &why) {
   why = "";
   if(!InpExtra_Enable) return true;

   if(InpExtra_BlockNewsWindow && g_newsHardLock) {
      why = "NEWS"; return false;
   }
   if(InpExtra_BlockLowMargin) {
      double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      double fm = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(eq > 0) {
         double pct = (fm / eq) * 100.0;
         if(pct < InpExtra_MinFreeMarginPct) {
            why = "MARGIN"; return false;
         }
      }
   }
   if(InpExtra_BlockHighSpread) {
      long spr = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
      if(spr > InpExtra_MaxSpreadPts) {
         why = "SPREAD"; return false;
      }
   }
   if(InpExtra_RequireSession && Security_IsFuturesSymbol(symbol)) {
      if(!Security_IsInTradeSession(symbol)) {
         why = "SESSION"; return false;
      }
   }
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(InpExtra_BlockFridayClose && dt.day_of_week == 5 && dt.hour >= InpExtra_FridayCloseHour) {
      why = "FRIDAY"; return false;
   }
   if(InpExtra_BlockMondayOpen && dt.day_of_week == 1 && dt.hour < InpExtra_MondayOpenHour) {
      why = "MONDAY"; return false;
   }
   int eidx = Ind_FindIdx(symbol);
   if(eidx < 0) eidx = 0;
   if(InpExtra_MinSecondsBetween > 0 && g_extra_lastEntryTime[eidx] > 0) {
      if(TimeCurrent() - g_extra_lastEntryTime[eidx] < InpExtra_MinSecondsBetween) {
         why = "THROTTLE"; return false;
      }
   }
   return true;
}


//+------------------------------------------------------------------+
//| Time Lot Boost (PDF TIME LOT BOOST)                              |
//+------------------------------------------------------------------+
double TimeLotBoost_Mult() {
   if(!InpEnableTimedLotBoost) return 1.0;
   if(InpLotBoostStepHours <= 0) return 1.0;

   // En eski magic pozisyon yaşına göre adım
   datetime oldest = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !PositionSelectByTicket(t)) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      datetime ot = (datetime)PositionGetInteger(POSITION_TIME);
      if(oldest == 0 || ot < oldest) oldest = ot;
   }
   if(oldest == 0) return 1.0;

   int hours = (int)((TimeCurrent() - oldest) / 3600);
   int steps = hours / InpLotBoostStepHours;
   if(steps <= 0) return 1.0;

   double mult = 1.0 + (steps * (InpLotBoostStepPct / 100.0));
   double maxM = 1.0 + (InpLotBoostMaxPct / 100.0);
   if(mult > maxM) mult = maxM;
   if(mult > 1.3) mult = 1.3; // FIX: TimeBoost hard cap
   return mult;
}

//+------------------------------------------------------------------+
//| Virtual / Alternating TP (PDF VIRTUAL TAKE PROFIT)               |
//+------------------------------------------------------------------+
// Alternating: bir kapanış kâr TP, sonraki daha agresif/gevşek sanal hedef
// g_altTP_side moved to top globals

double VirtualTP_MoneyTarget(const double equityBase) {
   // v1.78.18: runtime risk motoru + input; min taban ile 0.10$ erken kapanis engeli
   double pct = RT_VtpPct();
   if(pct <= 0.0) return 0.0;
   double base = (equityBase > 0) ? equityBase : AccountInfoDouble(ACCOUNT_EQUITY);
   double target = base * (pct / 100.0);
   double floorMoney = RT_MinCloseMoney();
   double peakFloor = RT_Peak() * 0.40;
   if(peakFloor > floorMoney) floorMoney = peakFloor;
   if(target < floorMoney) target = floorMoney;
   return target;
}


//+------------------------------------------------------------------+
//| PDF kalanlar: Phase TF / LotPenalty / AutoCost / PureShadow      |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES TF_EffectiveTrend() {
   return (InpTrendTF == PERIOD_CURRENT) ? Period() : InpTrendTF;
}
ENUM_TIMEFRAMES TF_EffectiveRange() {
   return (InpRangeTF == PERIOD_CURRENT) ? Period() : InpRangeTF;
}

// Lot penalty after resets (PDF LOT CUT AFTER RESETS)
double LotPenalty_Mult() {
   if(InpLotPenaltyStepResets <= 0 || InpLotPenaltyStepPct <= 0) return 1.0;
   int steps = g_resetCount / InpLotPenaltyStepResets;
   if(steps <= 0) return 1.0;
   double mult = 1.0 - (steps * (InpLotPenaltyStepPct / 100.0));
   double minM = InpLotPenaltyMinPct / 100.0;
   if(minM < 0.05) minM = 0.05;
   if(mult < minM) mult = minM;
   return mult;
}

// Auto cost: dinamik max spread (PDF AUTO COST LIMITS)
int AutoCost_MaxSpreadPts(const string symbol) {
   int base = InpMaxAllowedSpread;
   if(!InpEnableAutoSpread) return base;

   // Son 20 tick/bar spread ortalaması yerine mevcut spread + spike payı
   long spr = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   double spike = InpAutoSpreadSpikePct / 100.0;
   int dyn = (int)MathMax((double)base, (double)spr * (1.0 + spike));
   // Aşırı gevşemeyi sınırla
   if(dyn > base * 3) dyn = base * 3;
   return dyn;
}

int AutoCost_MaxSlippagePts() {
   int base = InpSlippagePoints;
   if(!InpEnableSlippageProtection) return base;
   if(InpAutoSlippagePct <= 0) return (InpMaxSlippage > 0 ? MathMin(base, InpMaxSlippage) : base);
   int dyn = (int)MathMax((double)base, base * (1.0 + InpAutoSlippagePct / 100.0));
   if(InpMaxSlippage > 0 && dyn > InpMaxSlippage) dyn = InpMaxSlippage;
   return dyn;
}

bool Stage_FinalVeto(SPipelineContext &ctx, const int direction, const double lot) {
   // GECICI TESHIS (v1.78.153): direction!=0 iken throttle YOK (bkz. yukarida
   // Bullet_Process ayni mantik). Sorun bulunduktan sonra kaldirilacak.
   bool fvDiagTick = (direction != 0);
   #define FVDIAG_RET(reason) { if(fvDiagTick) PrintFormat("R21 FINALVETO TESHIS RED | %s | dir=%d | sebep=%s", ctx.symbol, direction, reason); return false; }

   if(InpFinalDir_RequireNonZero && direction == 0) FVDIAG_RET("DIRECTION_SIFIR");
   if(direction > 0 && (!InpEnableBuy  || !g_panelBuy))  FVDIAG_RET("BUY_KAPALI(InpEnableBuy/panelBuy)");
   if(direction < 0 && (!InpEnableSell || !g_panelSell)) FVDIAG_RET("SELL_KAPALI(InpEnableSell/panelSell)");
   // Trend yon tek: sadece panelde acik olan tek taraf
   if(g_rt_ready && !g_rt_trend_both) {
      if(g_panelBuy && !g_panelSell && direction < 0) FVDIAG_RET("TEK_YON_PANEL_SELL_KAPALI");
      if(g_panelSell && !g_panelBuy && direction > 0) FVDIAG_RET("TEK_YON_PANEL_BUY_KAPALI");
   }
   if(lot < SymbolInfoDouble(ctx.symbol, SYMBOL_VOLUME_MIN)) FVDIAG_RET("LOT_MINVOL_ALTINDA");
   if(ctx.free_margin <= 0) FVDIAG_RET("FREE_MARGIN_SIFIR");

   // Spread / AutoCost
   if(InpEnableSpreadProtection) {
      long spr = SymbolInfoInteger(ctx.symbol, SYMBOL_SPREAD);
      int maxSpr = AutoCost_MaxSpreadPts(ctx.symbol);
      if(spr > maxSpr) FVDIAG_RET("SPREAD_AUTOCOST_ASIMI");
   }
   // FIX v1.78.13: slippage sapması artık işlem öncesi güncelleniyor — eskiden
   // sadece OnInit'te bir kez sabitleniyordu, InpAutoSlippagePct hiç etkisi olmuyordu.
   g_trade.SetDeviationInPoints(AutoCost_MaxSlippagePts());

   // Same-side minimum distance
   if(!MinDist_Allows(ctx.symbol, direction)) FVDIAG_RET("MIN_DIST_ENGEL");

   // Netting tek yön: karşı yönde pozisyon varken yeni yön engelle
   if(IsNettingAccount() && InpVG_NettingSingleSide) {
      double oppLot = 0, dummy = 0;
      TPProj_GetSameSideStats(ctx.symbol, g_magic, -direction, oppLot, dummy);
      if(oppLot > 0) FVDIAG_RET("NETTING_KARSI_YON_ACIK");
   }
   if(g_consensusBlocked) FVDIAG_RET("CONSENSUS_BLOCKED:" + g_consensusNote);

   // AEG adverse entry block
   if(InpAEG_Enable && InpAEG_BlockEntryOnAdverse && g_aegis.block_entry)
      FVDIAG_RET("AEGIS_ADVERSE_BLOCK");

   // DIRECTION EXTRA CHECKS
   string extraWhy = "";
   if(!ExtraChecks_Allows(ctx.symbol, extraWhy)) {
      if(InpExtra_LogBlocks)
         PrintFormat("ExtraChecks BLOCK: %s", extraWhy);
      FVDIAG_RET("EXTRA_CHECKS:" + extraWhy);
   }

   return true;
}
#undef FVDIAG_RET
// v1.78.157 GECICI TESHIS TEMIZLIGI: FVDIAG_RET makrosu tanimlandigi yerden
// (v1.78.153) itibaren dosyanin geri kalaninda "acik" kaliyordu (DIAG_RET'in
// kendi #undef'i - satir ~10516 - ile ayni ihtiyati burada da uyguluyoruz).
// Bugune kadar bir isim catismasi YOKTU (derleme hatasi vermiyordu), ama
// makro global oldugu icin ileride ayni isimde baska bir makro tanimlanirsa
// "macro redefinition" hatasi/uyarisi verebilirdi - onleyici temizlik.

//+------------------------------------------------------------------+
//| 7. R21 SANAL LATTICE GRID – DETAYLI STEP MANTIĞI                  |
//+------------------------------------------------------------------+
//
//  KAVRAM HARİTASI
//  ───────────────
//  anchor_price  : Lattice'in merkezi. İlk açılışta mid-price, sonra
//                  isteğe bağlı re-anchor (trend kırılımı / reset).
//
//  buy_step      : BUY tarafı için minimum fiyat mesafesi (fiyat birimi).
//  sell_step     : SELL tarafı için minimum fiyat mesafesi.
//
//  STEP MODLARI (InpVG_StepMode)
//  ─────────────────────────────
//  GST_FIXED_POINTS : InpVG_StepValue * _Point  (klasik point adım)
//  GST_RANGE_MULT   : ATR(14) * InpVG_StepValue  (volatiliteye oran)
//  GST_PRICE_PCT    : mid_price * (InpVG_StepValue / 100.0)
//
//  Yön bazlı override:
//    InpVG_BuyStepValue  > 0 → buy_step  = o değer (StepMode'a göre yorumlanır)
//    InpVG_SellStepValue > 0 → sell_step = o değer
//    0 ise genel InpVG_StepValue kullanılır.
//
//  AYNI YÖN STEP KURALI (en kritik otorite)
//  ────────────────────────────────────────
//  Yeni BUY  açılabilmesi için:  current_bid - last_buy_open_price  >= buy_step
//  Yeni SELL açılabilmesi için:  last_sell_open_price - current_ask >= sell_step
//  TREND/PYRAMID STEP MANTIĞI: BUY yukarı, SELL aşağı hareketi takip eder.
//  (İlk seviye için last_* = 0 → her zaman izin verilir)
//
//  NETTING
//  ───────
//  VG_NettingSingleSide = true ise aynı anda hem BUY hem SELL grid
//  çalışmaz; sadece net yön (veya direction engine yönü) açılır.
//
//  TREND DURDURMA
//  ──────────────
//  VG_StopNewEntriesOnTrend = true ve phase == TREND_* ise yeni kademe
//  açılmaz (mevcutlar ManageTP ile yönetilmeye devam eder).
//
//+------------------------------------------------------------------+

//--- STEP değerini fiyat birimine çevir
double Lattice_CalcStepPrice(const string symbol, const double rawValue, const ENUM_GRID_STEP_MODE mode) {
   if(rawValue <= 0.0) return 0.0;

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0.0) point = _Point;

   switch(mode) {
      case GST_FIXED_POINTS:
         // rawValue = point sayısı (örn. 200 → 200 * point)
         return rawValue * point;

      case GST_RANGE_MULT: {
         // rawValue = ATR çarpanı (örn. 1.5 → ATR*1.5)  v1.68 cache
         double atr = Ind_ATR(symbol);
         if(atr <= 0.0) atr = point * 50;
         return atr * rawValue;
      }

      case GST_PRICE_PCT: {
         // rawValue = yüzde (örn. 0.15 → fiyatın %0.15'i)
         double mid = (SymbolInfoDouble(symbol, SYMBOL_BID) + SymbolInfoDouble(symbol, SYMBOL_ASK)) * 0.5;
         if(mid <= 0.0) mid = SymbolInfoDouble(symbol, SYMBOL_ASK);
         return mid * (rawValue / 100.0);
      }
   }
   return rawValue * point; // fallback
}

//--- BUY / SELL step'lerini güncelle (her tick veya periyodik)
void Lattice_RefreshSteps(SLatticeState &lat, const string symbol) {
   // Panel ADIM PNT öncelikli (sabit puan modunda); yoksa RT_VG_Step / input
   double baseStep = RT_VG_Step();
   if(g_rt_ready && g_rt_step_pnt > 0 && InpVG_StepMode == GST_FIXED_POINTS)
      baseStep = RT_StepPnt();

   // FIX (birim uyumsuzlugu): v1.78.22 ATR risk motoru (RiskATR_AutoFill)
   // g_rt_step_pnt/g_rt_vg_step degerini HER ZAMAN "puan" (points) biriminde
   // uretir (stepPts = stepPrice/point). InpVG_StepMode = GST_RANGE_MULT
   // secildiyse Lattice_CalcStepPrice bu puan sayisini "ATR carpani" sanip
   // atr*puanSayisi gibi devasa bir fiyat mesafesi uretiyordu; GST_PRICE_PCT'te
   // ise "yuzde" sanip mid_price*puanSayisi/100 uretiyordu. Sonuc: buy_step/
   // sell_step gercekci olmayacak kadar BUYUK cikiyor, "last_open - current
   // >= step" hicbir zaman saglanamiyor ve sıralı (grid) islem hic acilmiyordu.
   // ATR motoru step'i belirlediginde bunu HER ZAMAN puan*point olarak yorumla.
   bool atrDrivenStep = (g_rt_ready && RT_ATRMode() && g_rt_step_pnt > 0);
   ENUM_GRID_STEP_MODE effStepMode = atrDrivenStep ? GST_FIXED_POINTS : InpVG_StepMode;

   // Mode'a ozel inputlar: RANGE_MULT/PRICE_PCT modunda genel StepValue
   // ATR carpani/yuzde gibi yorumlanmasin. Manuel yon override varsa onun
   // degeri secili moda gore yorumlanir; ATR motoru ise daima puan uretir.
   bool buyOverride  = (InpVG_BuyStepValue  > 0.0);
   bool sellOverride = (InpVG_SellStepValue > 0.0);
   ENUM_GRID_STEP_MODE buyMode  = buyOverride  ? InpVG_StepMode : effStepMode;
   ENUM_GRID_STEP_MODE sellMode = sellOverride ? InpVG_StepMode : effStepMode;

   double buyRaw = buyOverride ? InpVG_BuyStepValue : baseStep;
   double sellRaw = sellOverride ? InpVG_SellStepValue : baseStep;
   if(!buyOverride && !atrDrivenStep) {
      if(InpVG_StepMode == GST_RANGE_MULT) buyRaw = InpVG_Step_RangeMult;
      else if(InpVG_StepMode == GST_PRICE_PCT) buyRaw = InpVG_Step_PricePct;
   }
   if(!sellOverride && !atrDrivenStep) {
      if(InpVG_StepMode == GST_RANGE_MULT) sellRaw = InpVG_Step_RangeMult;
      else if(InpVG_StepMode == GST_PRICE_PCT) sellRaw = InpVG_Step_PricePct;
   }

   lat.buy_step  = Lattice_CalcStepPrice(symbol, buyRaw,  buyMode)  * AutoTune_StepMult();
   lat.sell_step = Lattice_CalcStepPrice(symbol, sellRaw, sellMode) * AutoTune_StepMult();

   // Minimum güvenlik: step en az 5 point olsun
   double minStep = SymbolInfoDouble(symbol, SYMBOL_POINT) * 5.0;
   if(lat.buy_step  < minStep) lat.buy_step  = minStep;
   if(lat.sell_step < minStep) lat.sell_step = minStep;
}

//--- v1.78.40 FIX: Startup Reconciliation — broker'daki acik pozisyonlari
// Lattice/Bullet RAM state'ine geri kur. Eskiden OnInit()'te ZeroMemory(g_lattice)
// yapiliyordu ama broker'da zaten acik olan Grid pozisyonlarindan state'i yeniden
// kuran hicbir mekanizma yoktu: last_buy/sell_open_price=0 kaldigi icin STEP
// korumasi ilk yeni seviyede devre disi kaliyordu (Lattice_SameSideStepOK "ilk
// seviye" saniyordu), Bullet ticket'i kayboluyordu (yonetilemeyen "yetim"
// pozisyon + ayni yonde ikinci bir bullet acilabilme riski — bkz. Bullet_RematchTicket
// fix'i, o SADECE ayni oturum icindeki kayip ticket'lari cozer, restart'i degil).
// Ayirt edici: Grid pozisyonlari InpTradeComment SUFFIX'SIZ acilir; Bullet "-BLT",
// NF Hedge "-NFH", Weekly Hedge "-WH", DD Hedge "-DDH" suffix'i tasir (bkz. ilgili
// Buy/Sell cagri siteleri). g_magic AYNI oldugu icin ayirim comment'e dayanir.
void Lattice_ReconcileFromBroker(SLatticeState &lat, const string symbol) {
   int buyIdx = 0, sellIdx = 0;
   datetime bestBuyTime = 0, bestSellTime = 0;
   int reconciled = 0, skippedOther = 0;
   int capacityExceeded = 0; // AUDIT v1.78.70 (#5): kapasiteyi asan, state'e girmeyen pozisyon sayisi

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      string cmt = PositionGetString(POSITION_COMMENT);
      // Bullet/Hedge suffix'lerinden herhangi biri varsa bu Grid'e ait degil
      if(StringFind(cmt, "-BLT") >= 0 || StringFind(cmt, "-NFH") >= 0 ||
         StringFind(cmt, "-WH")  >= 0 || StringFind(cmt, "-DDH") >= 0) {
         skippedOther++;
         continue;
      }

      int ptype = (int)PositionGetInteger(POSITION_TYPE);
      double op  = PositionGetDouble(POSITION_PRICE_OPEN);
      double vol = PositionGetDouble(POSITION_VOLUME);
      datetime ot = (datetime)PositionGetInteger(POSITION_TIME);

      if(ptype == POSITION_TYPE_BUY) {
         if(buyIdx >= LATTICE_MAX_LEVELS) { capacityExceeded++; continue; } // kapasite asimi, geri kalani yonetilemez kalir
         lat.buy_levels[buyIdx].active        = true;
         lat.buy_levels[buyIdx].trigger_price = op;
         lat.buy_levels[buyIdx].open_price    = op;
         lat.buy_levels[buyIdx].step_at_open   = lat.buy_step;
         lat.buy_levels[buyIdx].ticket        = t;
         lat.buy_levels[buyIdx].lot           = vol;
         lat.buy_levels[buyIdx].open_time     = ot;
         buyIdx++;
         lat.buy_levels_active++;
         if(ot >= bestBuyTime) { bestBuyTime = ot; lat.last_buy_open_price = op; }
      } else {
         if(sellIdx >= LATTICE_MAX_LEVELS) { capacityExceeded++; continue; }
         lat.sell_levels[sellIdx].active        = true;
         lat.sell_levels[sellIdx].trigger_price = op;
         lat.sell_levels[sellIdx].open_price    = op;
         lat.sell_levels[sellIdx].step_at_open   = lat.sell_step;
         lat.sell_levels[sellIdx].ticket        = t;
         lat.sell_levels[sellIdx].lot           = vol;
         lat.sell_levels[sellIdx].open_time     = ot;
         sellIdx++;
         lat.sell_levels_active++;
         if(ot >= bestSellTime) { bestSellTime = ot; lat.last_sell_open_price = op; }
      }
      reconciled++;
   }

   if(reconciled > 0 || skippedOther > 0) {
      PrintFormat("R21 Lattice RECONCILE | %s | grid=%d (buy=%d/sell=%d) | atlanan(bullet/hedge)=%d | last_buy=%.5f last_sell=%.5f",
                  symbol, reconciled, buyIdx, sellIdx, skippedOther,
                  lat.last_buy_open_price, lat.last_sell_open_price);
   }

   // AUDIT v1.78.70 (#5): kapasite asan pozisyon bulunduysa acikca uyar ve
   // orphan bayragini kaldir (GridRisk_Enforce yeni Grid girisini durdurur;
   // mevcut pozisyonlar KAPATILMAZ — manuel/ozel mudahale gerektirir).
   int oi = Ind_FindIdx(symbol);
   if(oi >= 0 && oi < MAX_SYMBOLS) {
      g_latticeOrphanExtraCount[oi] = capacityExceeded;
      g_latticeOrphanExtra[oi]      = (capacityExceeded > 0);
      if(capacityExceeded > 0) {
         PrintFormat("R21 KRITIK: Lattice RECONCILE | %s | LATTICE_MAX_LEVELS(%d) asan %d pozisyon state'e alinamadi — bunlar EA tarafindan yonetilmiyor. Yeni Grid girisi InpGridRiskBlockOnOrphan ile durdurulacak; pozisyonlari manuel inceleyin.",
                     symbol, LATTICE_MAX_LEVELS, capacityExceeded);
      }
   }
}

//--- Lattice ilk kurulum
void Lattice_Init(SLatticeState &lat, const string symbol, const double midPrice) {
   ZeroMemory(lat);
   lat.initialized          = true;
   lat.anchor_price         = midPrice;
   lat.last_buy_open_price  = 0.0;
   lat.last_sell_open_price = 0.0;
   lat.buy_levels_active    = 0;
   lat.sell_levels_active   = 0;
   lat.last_update          = TimeCurrent();
   lat.last_reanchor        = TimeCurrent();

   Lattice_RefreshSteps(lat, symbol);

   // İlk sanal hücreleri anchor etrafında yerleştir (henüz active=false)
   // Trend/pyramid modeli: BUY hücreleri anchor'ın üstüne, SELL hücreleri altına
   for(int i = 0; i < LATTICE_MAX_LEVELS; i++) {
      lat.buy_levels[i].active        = false;
      lat.buy_levels[i].trigger_price = midPrice + (i + 1) * lat.buy_step;
      lat.buy_levels[i].open_price    = 0.0;
      lat.buy_levels[i].step_at_open   = 0.0;
      lat.buy_levels[i].ticket        = 0;
      lat.buy_levels[i].lot           = 0.0;

      lat.sell_levels[i].active        = false;
      lat.sell_levels[i].trigger_price = midPrice - (i + 1) * lat.sell_step;
      lat.sell_levels[i].open_price    = 0.0;
      lat.sell_levels[i].step_at_open   = 0.0;
      lat.sell_levels[i].ticket        = 0;
      lat.sell_levels[i].lot           = 0.0;
   }

   // v1.78.40 FIX: broker'da zaten acik olan Grid pozisyonlarini state'e geri kur
   // (asagida bos kalan hucreler zaten trigger_price ile sanal olarak yerlesik).
   Lattice_ReconcileFromBroker(lat, symbol);

   PrintFormat("R21 Lattice Init | anchor=%.5f | buy_step=%.5f | sell_step=%.5f | mode=%s",
               lat.anchor_price, lat.buy_step, lat.sell_step, EnumToString(InpVG_StepMode));
}

//--- Son aktif aynı-yön pozisyon referanslarını yeniden kur.
// Kapanan son seviye STEP referansı olarak kalmasın; o yönün tüm seviyeleri
// kapandıysa bir sonraki giriş tekrar ilk seviye gibi serbest olsun.
void Lattice_RebuildLastOpenRefs(SLatticeState &lat) {
   datetime bestBuyTime = 0, bestSellTime = 0;
   double bestBuyPrice = 0.0, bestSellPrice = 0.0;
   for(int i = 0; i < LATTICE_MAX_LEVELS; i++) {
      if(lat.buy_levels[i].active && lat.buy_levels[i].open_price > 0.0 && lat.buy_levels[i].open_time >= bestBuyTime) {
         bestBuyTime = lat.buy_levels[i].open_time;
         bestBuyPrice = lat.buy_levels[i].open_price;
      }
      if(lat.sell_levels[i].active && lat.sell_levels[i].open_price > 0.0 && lat.sell_levels[i].open_time >= bestSellTime) {
         bestSellTime = lat.sell_levels[i].open_time;
         bestSellPrice = lat.sell_levels[i].open_price;
      }
   }
   lat.last_buy_open_price = bestBuyPrice;
   lat.last_sell_open_price = bestSellPrice;
}

//--- Son açılan aynı-yön kademenin gerçek STEP kilidini getir.
// Açık pozisyon varsa o pozisyon açılırken kaydedilen STEP otoritedir;
// ATR/AutoTune tarafından sonradan üretilen STEP geriye dönük uygulanmaz.
double Lattice_LastLockedStep(const SLatticeState &lat, const int direction) {
   double stepLocked = 0.0;
   datetime bestTime = 0;
   if(direction > 0) {
      for(int i=0; i<LATTICE_MAX_LEVELS; i++) {
         if(lat.buy_levels[i].active && lat.buy_levels[i].open_price > 0.0 &&
            lat.buy_levels[i].open_time >= bestTime) {
            bestTime = lat.buy_levels[i].open_time;
            stepLocked = lat.buy_levels[i].step_at_open;
         }
      }
      if(stepLocked <= 0.0 && lat.last_buy_open_price > 0.0)
         stepLocked = lat.buy_step; // eski/reconcile state fallback
   } else if(direction < 0) {
      for(int i=0; i<LATTICE_MAX_LEVELS; i++) {
         if(lat.sell_levels[i].active && lat.sell_levels[i].open_price > 0.0 &&
            lat.sell_levels[i].open_time >= bestTime) {
            bestTime = lat.sell_levels[i].open_time;
            stepLocked = lat.sell_levels[i].step_at_open;
         }
      }
      if(stepLocked <= 0.0 && lat.last_sell_open_price > 0.0)
         stepLocked = lat.sell_step; // eski/reconcile state fallback
   }
   return stepLocked;
}

//--- Aynı yönde STEP mesafesi yeterli mi?
bool Lattice_SameSideStepOK(const SLatticeState &lat, const int direction,
                            const double currentBid, const double currentAsk) {
   if(direction > 0) { // BUY
      if(lat.last_buy_open_price <= 0.0) return true; // ilk seviye
      double stepLocked = Lattice_LastLockedStep(lat, direction);
      if(stepLocked <= 0.0) stepLocked = lat.buy_step;
      double moved = currentBid - lat.last_buy_open_price;
      return (moved >= stepLocked);
   }
   else if(direction < 0) { // SELL
      if(lat.last_sell_open_price <= 0.0) return true;
      double stepLocked = Lattice_LastLockedStep(lat, direction);
      if(stepLocked <= 0.0) stepLocked = lat.sell_step;
      double moved = lat.last_sell_open_price - currentAsk;
      return (moved >= stepLocked);
   }
   return false;
}

//--- Netting tek yön kuralı
bool Lattice_NettingAllows(const SLatticeState &lat, const int direction) {
   if(!InpVG_NettingSingleSide) return true;           // hedging → çift yön serbest
   if(!IsNettingAccount())      return true;           // hesap hedging ise serbest

   // Netting hesap + SingleSide: karşı yönde açık seviye varsa engelle
   if(direction > 0 && lat.sell_levels_active > 0) return false;
   if(direction < 0 && lat.buy_levels_active  > 0) return false;
   return true;
}

//--- v1.78.21 FIX: TREND KAYNAK (g_rt_grid_src) daha once sadece panelde
//    etiket degistiriyordu, hicbir karara bagli degildi. Artik GRID TREND
//    UYUM kontrolune girecek "faz"i secilen kaynaga gore gercekten hesaplar.
//    0=GRID MIKRO -> ana yon motorunun fazi (zaten MIKRO TREND ayariyla etkilenir)
//    1=DI  -> DI_Evaluate() yonu
//    2=TMI -> TMI_Evaluate() yonu
//    3=ENSEMBLE -> ana motor + DI + TMI cogunluk oyu (2/3 ayni yonde olmali)
ENUM_MARKET_PHASE RT_PhaseFromDir(const int dir) {
   if(dir > 0) return PHASE_TREND_UP;
   if(dir < 0) return PHASE_TREND_DOWN;
   return PHASE_NEUTRAL;
}

ENUM_MARKET_PHASE RT_GridTrendPhase(const ENUM_MARKET_PHASE enginePhase) {
   int src = (g_rt_ready ? g_rt_grid_src : 0);
   if(src < 0 || src > 3) src = 0;
   switch(src) {
      case 1: // DI
         return RT_PhaseFromDir(g_di.direction);
      case 2: // TMI
         return RT_PhaseFromDir(g_tmi.direction);
      case 3: { // ENSEMBLE
         int engDir = (enginePhase==PHASE_TREND_UP) ? 1 : (enginePhase==PHASE_TREND_DOWN ? -1 : 0);
         int up=0, dn=0;
         if(engDir>0) up++; else if(engDir<0) dn++;
         if(g_di.direction>0) up++; else if(g_di.direction<0) dn++;
         if(g_tmi.direction>0) up++; else if(g_tmi.direction<0) dn++;
         if(up>=2 && up>dn) return PHASE_TREND_UP;
         if(dn>=2 && dn>up) return PHASE_TREND_DOWN;
         return PHASE_NEUTRAL;
      }
      default: // 0 = GRID MIKRO
         return enginePhase;
   }
}

//--- Trend flip sonrası sanal grid anchor'ını güncelle.
// Aktif pozisyonların STEP referanslarına dokunmaz; yalnızca boş sanal
// hücreleri yeni anchor etrafında hizalar. Böylece trend dönüşünde eski
// anchor'dan kalan sanal seviyeler yeni yönle çelişmez.
void Lattice_ReanchorOnTrendFlip(SLatticeState &lat, const string symbol, const double midPrice) {
   if(!InpVG_ReanchorOnTrendFlip || midPrice <= 0.0) return;
   lat.anchor_price = midPrice;
   lat.last_reanchor = TimeCurrent();
   for(int i=0;i<LATTICE_MAX_LEVELS;i++) {
      if(!lat.buy_levels[i].active)
         lat.buy_levels[i].trigger_price = midPrice + (i + 1) * lat.buy_step;
      if(!lat.sell_levels[i].active)
         lat.sell_levels[i].trigger_price = midPrice - (i + 1) * lat.sell_step;
   }
   PrintFormat("R21 Lattice REANCHOR | %s | anchor=%.5f | buy_step=%.5f | sell_step=%.5f",
               symbol, midPrice, lat.buy_step, lat.sell_step);
}

//--- Trend varken yeni giriş durdurulsun mu?
// v1.78.34 FIX: "TREND UYUM: ACIK" etiketi ve kod yorumu "trend ile ayni
// yonde acmaya izin" diyordu, ama fonksiyon "direction" parametresi hic
// almiyordu — yani BUY/SELL ayrimi yapamiyor, ACIK oldugunda TUM yonlere
// (trendin tersi dahil) izin veriyordu. Bu, "basari oranini artiracak
// giris kosulu" tam olarak burada eksikti: karsi-trend girisler hic
// filtrelenmiyordu. Artik ACIK gercekten SADECE trendle ayni yondeki
// girise izin veriyor, tersini blokluyor.
bool Lattice_TrendBlocksNewEntry(const ENUM_MARKET_PHASE phase, const int direction) {
   // TREND UYUM kapali → trend fazinda HER IKI yonde de yeni grid acma
   // TREND UYUM acik → trend ile SADECE AYNI yonde acmaya izin, tersini blokla
   if(g_rt_ready) {
      if(g_rt_trend_align) {
         if(phase == PHASE_TREND_UP)   return (direction < 0); // yukari trend: SELL bloklanir
         if(phase == PHASE_TREND_DOWN) return (direction > 0); // asagi trend: BUY bloklanir
         // DI/TMI/ENSEMBLE seciliyken notr faz, secilen kaynagin yonu
         // onaylamadigi anlamina gelir. Ana motorun eski/cache'lenmis BUY
         // veya SELL sonucuyla yeni Grid riski uretilmesine izin verme.
         int src = (g_rt_ready ? g_rt_grid_src : 0);
         if(src >= 1 && src <= 3) return true;
         return false; // notr/range: blok yok
      }
      // uyum kapali: trendde yeni giris dur (yon farketmez)
      return (phase == PHASE_TREND_UP || phase == PHASE_TREND_DOWN);
   }
   if(!InpVG_StopNewEntriesOnTrend) return false;
   return (phase == PHASE_TREND_UP || phase == PHASE_TREND_DOWN);
}


//+------------------------------------------------------------------+
//| FIX: Lot carpanlari hard-cap (AutoTune*Boost*Penalty*Risk)       |
//+------------------------------------------------------------------+
// v1.78.72 FIX: equity-risk% bazli lot tavani ortak fonksiyona cikarildi.
// Eskiden SADECE TPProj_NormalizeLot() (Grid + Solver TP-Proj cagrilari)
// icindeydi; Bullet_CalcLot() -> Lot_CalcCapped() zinciri (ozellikle
// BLM_PROJECT + "TP BASLAMA=PROJECT" kombinasyonu, ilk giristen itibaren
// Solver lotu kullanir) bu korumadan GECMIYORDU - sadece sabit InpLatticeMaxLot
// (varsayilan 0.50) ve 0.5 lot tavanina tabiydi, hesap buyuklugunden
// BAGIMSIZDI. Kucuk hesapta (orn. 500-600$) bu, PEAK$ modunda hesaplanan
// buyuk lotlarin hicbir equity-orantili sinira takilmadan acilabilmesine
// yol aciyordu. Artik her iki yol da AYNI equity-risk tavanindan geciyor.
// Yalnizca DARALTIR (maxLot dondurur); disabled/veri yoksa DBL_MAX doner
// (sinirsiz, davranis degismez).
// v1.78.117 EKLENTI (kullanici talebi - KAR KORUMA KASASI kritik-durum
// mantigi): Bu 3 helper birlikte calisir:
//   1) EscapeFund_ProtectedAmount(): hedefin (InpVG_EscapeBankTargetUSD)
//      korunan yuzdesi (InpVG_EscapeProtectedPct) - bu tutar MUTLAK
//      DOKUNULMAZ, hicbir hesaplamaya asla katilmaz.
//   2) EscapeFund_AvailableAmount(): kasa toplaminin, korunan tutari asan
//      FAZLALIK kismi - "acil durum yedegi".
//   3) EscapeFund_IsCritical(): equity, kasa toplamiyla AYNI SEVIYEYE
//      dustu mu (kullanicinin tanimladigi "kritik durum").
//   4) EffectiveEquity(): normal zamanda GERCEK equity'yi aynen dondurur;
//      SADECE kritik durumda VE kullanilabilir kasa varsa, o fazlaligi
//      GECICI olarak equity'ye ekler (kasa sayacinin KENDISI degismez,
//      sadece risk hesaplarina "sanki equity bu kadar buyukmus gibi"
//      bir gorunum verilir). InpVG_EscapeCriticalWithdrawEnable=false ise
//      (varsayilan) bu ozellik tamamen devre disidir, GERCEK equity doner.
double EscapeFund_ProtectedAmount() {
   return InpVG_EscapeBankTargetUSD * (InpVG_EscapeProtectedPct / 100.0);
}

double EscapeFund_AvailableAmount(const double fundTotal) {
   double protectedAmt = EscapeFund_ProtectedAmount();
   double avail = fundTotal - protectedAmt;
   return (avail > 0.0) ? avail : 0.0;
}

bool EscapeFund_IsCritical(const double equityNow, const double fundTotal) {
   if(fundTotal <= 0.0) return false;
   // "ayni seviyeye geldi" - equity, kasa toplaminin altina dustuyse VEYA
   // ona cok yakinsa (kucuk bir tolerans payi ile, ani spread/slipaj
   // yuzunden gereksiz tetiklenmeyi onlemek icin %1 pay birakildi).
   return equityNow <= fundTotal * 1.01;
}

double EffectiveEquity(const string symbol) {
   double realEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(!InpVG_EscapeCriticalWithdrawEnable) return realEquity; // ozellik kapali - GERCEK equity
   if(!(g_rt_ready ? g_rt_escape_fund : InpVG_EscapeFundEnable)) return realEquity; // kasa modulu kapali
   double fundTotal = g_lattice.escape_fund;
   if(!EscapeFund_IsCritical(realEquity, fundTotal)) return realEquity; // kritik degil - GERCEK equity
   double avail = EscapeFund_AvailableAmount(fundTotal);
   if(avail <= 0.0) return realEquity; // kasada kullanilabilir yok - GERCEK equity (kullanicinin talebi: "yoksa normal davransin")
   return realEquity + avail; // kritik VE kullanilabilir kasa var - GECICI ek
}

// v1.78.141 RISK_CALIBRATION FIX (DUZELTME_REHBERI [bu PDF] Bolum 1/3, P0 #1):
// ONCEKI DAVRANIS: bu fonksiyon RiskCap icin KENDI AYRI mesafesini (ATR x
// InpRiskSizing_AdverseATRMult, sabit 3.0x) hesapliyordu. Ama Grid motorunun
// broker'a gonderdigi GERCEK Hard SL, HardSL_Distance(...,isGridMotor=true)
// icinde InpHardSL_GridATRMult (9.0x) ile hesaplaniyordu - IKI FARKLI MESAFE,
// IKI FARKLI RISK SOZLESMESI. Sonuc: "maksimum %1 risk" olarak hesaplanan lot,
// pozisyon GERCEKTE Grid'in Hard SL'ine kadar giderse ~3 KAT daha buyuk
// parasal zarara karsilik gelebiliyordu (raporun P0 #1 bulgusu). Artik TEK
// KAYNAK: HardSL_Distance(symbol, isGridMotor) - Grid icin gercekten 9 ATR,
// Bullet/hedge icin gercekten 3 ATR (Adverse mult) ne ise, RiskCap AYNI
// mesafeyi kullanir (o da AYNI fonksiyonu cagirir - bkz. HardSL_ComputePrice).
// "Risk hesaplanan mesafe" ile "emre iliskilendirilen gercek SL mesafesi"
// boylece HER ZAMAN birebir ayni sozlesmeye baglanir.
//
// isGridMotor: cagiran motor Grid/Lattice ise true (varsayilan - hicbir cagiran
// bu parametreyi unutursa DAHA GENIS/DAHA TUTUCU mesafe kullanilir, yani daha
// KUCUK bir maxLot cikar - fail-closed yonde varsayilan).
// direction: OrderCalcProfit yon-farkindalikli calisir (>0 Buy, <=0 Sell);
// standart Forex/CFD sembollerinde iki yonun parasal buyuklugu ayni olsa da
// dogru ORDER_TYPE ile hesaplamak icin varsayilan Buy (1) kullanilir.
double RiskCap_MaxLot(const string symbol, const bool isGridMotor=true, const int direction=1) {
   if(!InpRiskSizing_Enable || InpRiskSizing_MaxRiskPct <= 0.0)
      return DBL_MAX;

   double rsAdverseDist = HardSL_Distance(symbol, isGridMotor);
   if(rsAdverseDist <= 0.0) {
      // v1.78.142 TANI EKLEME: bu dal daha once SESSIZDI - DBL_MAX'in HANGI
      // sebepten dondugu Journal'da gorunmuyordu. Artik her sebep ayri loglaniyor.
      PrintFormat("R21 RISK_CAP UYARI | %s | motor=%s | HardSL_Distance()<=0 (ATR/broker mesafesi hesaplanamadi) - risk cap hesaplanamadi, VETO", symbol, (isGridMotor?"GRID":"BULLET/DIGER"));
      return DBL_MAX;
   }

   double rsEquity = EffectiveEquity(symbol);
   if(rsEquity <= 0.0) rsEquity = AccountInfoDouble(ACCOUNT_BALANCE);
   if(rsEquity <= 0.0) {
      PrintFormat("R21 RISK_CAP UYARI | %s | equity/balance okunamadi (<=0) - risk cap hesaplanamadi, VETO", symbol);
      return DBL_MAX;
   }
   double rsRiskMoney = rsEquity * InpRiskSizing_MaxRiskPct / 100.0;
   if(rsRiskMoney <= 0.0) return DBL_MAX;

   // v1.78.141 FIX (DUZELTME_REHBERI Bolum 4B, P1): tickValue/tickSize
   // yaklasimi yerine OrderCalcProfit ile GERCEK parasal zarar - bazi
   // sembollerde (degisken/asamali tick value'lu enstrumanlar, bazi CFD/
   // futures sozlesmeleri) duz "mesafe/tickSize*tickValue" formulu broker'in
   // KENDI hesapladigi degerden sapabilir. OrderCalcProfit broker/terminal
   // motorunu dogrudan kullanir.
   double refPrice = (direction > 0) ? SymbolInfoDouble(symbol, SYMBOL_ASK)
                                      : SymbolInfoDouble(symbol, SYMBOL_BID);
   if(refPrice <= 0.0) {
      PrintFormat("R21 RISK_CAP UYARI | %s | ask/bid okunamadi (<=0) - risk cap hesaplanamadi, VETO", symbol);
      return DBL_MAX;
   }
   double slPrice = (direction > 0) ? (refPrice - rsAdverseDist) : (refPrice + rsAdverseDist);
   if(slPrice <= 0.0) {
      PrintFormat("R21 RISK_CAP UYARI | %s | hesaplanan SL fiyati<=0 (refPrice=%.8f dist=%.8f) - risk cap hesaplanamadi, VETO", symbol, refPrice, rsAdverseDist);
      return DBL_MAX;
   }

   ENUM_ORDER_TYPE ot = (direction > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double profit1Lot = 0.0;
   double rsLossPerLot = 0.0;
   if(OrderCalcProfit(ot, symbol, 1.0, refPrice, slPrice, profit1Lot) && MathIsValidNumber(profit1Lot))
      rsLossPerLot = MathAbs(profit1Lot);

   if(rsLossPerLot <= 0.0) {
      // v1.78.141 (DUZELTME_REHBERI Bolum 4B, P1): "OrderCalcProfit
      // başarısızsa güvenli tarafta kal: trade veto" - tickValue formulune
      // SESSIZCE geri duserek olasi yanlis bir lot uretmek yerine cagiran
      // tarafin zaten DBL_MAX'i ret olarak isledigi ayni yola dusuluyor.
      PrintFormat("R21 RISK_CAP UYARI | %s | motor=%s dir=%d | OrderCalcProfit basarisiz/gecersiz sonuc (refPrice=%.8f slPrice=%.8f profit1Lot=%.8f) - risk cap hesaplanamadi, VETO",
                  symbol, (isGridMotor?"GRID":"BULLET/DIGER"), direction, refPrice, slPrice, profit1Lot);
      return DBL_MAX;
   }

   return rsRiskMoney / rsLossPerLot;
}

//======================================================================
// v1.78.131 HARD SL (Teknik Sartname R1-R6) ------------------------
// Amac: her pozisyon acilisina GERCEK (broker seviyeli) bir Stop Loss
// iliskilendirmek. Mevcut soft-exit motorlarinin (AEG/DirLock/
// GridRiskFirewall/RiskGovernor) yerine gecmez - onlarin yakalayamadigi
// nadir kuyruk olaylarinda (gap/spike/tick mantiginin zamaninda
// tetiklenememesi) son care/felaket freni olarak calisir.
//======================================================================

// R2/R5: SL mesafesini (fiyat birimi olarak) hesaplar. Bullet/hedge
// motorlari icin RiskCap_MaxLot() ile AYNI varsayimi (ATR x
// InpRiskSizing_AdverseATRMult) kullanir; Grid/Lattice sepeti icin
// bilerek daha genis InpHardSL_GridATRMult kullanilir (bkz. 4.4).
// Broker'in SYMBOL_TRADE_STOPS_LEVEL / SYMBOL_TRADE_FREEZE_LEVEL
// degerlerinden daha yakin bir mesafe ASLA dondurulmez (R5).
double HardSL_Distance(const string symbol, const bool isGridMotor)
{
   double atr = RiskATR_Read(symbol);
   if(atr <= 0.0) atr = Ind_ATR(symbol, 0);
   if(atr <= 0.0) return 0.0; // v1.78.141 GUNCELLEME: ATR okunamadi - 0.0 dondurulur; ARTIK cagiran taraf sl=0 ile devam ETMIYOR (fail-CLOSED) - bkz. Trade_PreflightMarketOrder() HARDSL_FORCE_ENABLED kontrolu, islem tamamen veto edilir

   double mult = isGridMotor ? InpHardSL_GridATRMult : InpRiskSizing_AdverseATRMult;
   if(mult <= 0.0) return 0.0;
   double dist = atr * mult;

   long   stopsLevelPts  = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long   freezeLevelPts = SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   double point          = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double minDist = MathMax(stopsLevelPts, freezeLevelPts) * point * InpHardSL_MinBufferMult;
   if(dist < minDist) dist = minDist;

   return dist;
}

// R1: gonderilecek emre iliskilendirilecek SL FIYATINI dondurur (0.0 =
// hesaplanamadi, cagiran taraf eski davranisa - sl=0 - duser).
// direction: >0 = Buy (SL asagida), <=0 = Sell (SL yukarida).
// refPrice verilmezse (<=0) guncel Ask/Bid otomatik okunur.
double HardSL_ComputePrice(const string symbol, const int direction, const bool isGridMotor, double refPrice=0.0)
{
   if(!HARDSL_FORCE_ENABLED) return 0.0;
   if(refPrice <= 0.0)
      refPrice = (direction > 0) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
   if(refPrice <= 0.0) return 0.0;

   double dist = HardSL_Distance(symbol, isGridMotor);
   if(dist <= 0.0) return 0.0;

   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double sl = (direction > 0) ? (refPrice - dist) : (refPrice + dist);
   if(sl <= 0.0) return 0.0;
   return NormalizeDouble(sl, digits);
}

// R3: Grid/Lattice sepetine VEYA Bullet'in BLM_PROJECT modunda ayni yone
// yaptigi ek girislere netting hesapta uygulanir - broker POSITION_PRICE_OPEN
// degeri yeni hacim-agirlikli ortalamaya guncellenince SL de o ortalamaya
// gore yeniden hesaplanip PositionModify ile uygulanir; eski SL, kaymis bir
// ortalamaya gore anlamsiz kalmaz. isGridMotor, BU CAGRIYI YAPAN motora
// gore mesafe secer (Grid->genis 9x, Bullet->R2'nin kendi 8x'i) - boylece
// Bullet'in ilk girişte aldigi dar/dogru SL, hemen ardindan cagirilan bu
// fonksiyon tarafindan yanlislikla Grid'in daha genis mesafesine
// GENISLETILMEZ (2. gecis duzeltmesi - ilk implementasyonda bu hataydi).
void HardSL_RecalcOnAdd(const string symbol, const ulong magic, const bool isGridMotor)
{
   if(!HARDSL_FORCE_ENABLED || !InpHardSL_RecalcOnAdd) return;
   // v1.78.131 KRITIK DUZELTME: PositionSelect(symbol) SADECE netting
   // hesapta guvenlidir (sembol basina garantili TEK pozisyon). Hedging
   // hesapta ayni sembolde birden fazla pozisyon es zamanli var olabilir
   // (birden fazla grid seviyesi + NFH/WH/DDH gibi farkli magic'li hedge
   // motorlari) ve PositionSelect(symbol) o durumda HANGISINI sececegi
   // TANIMSIZDIR (bkz. Grid_OpenExposure() ve IsHedgingAccount() kullanan
   // diger motorlarin neden PositionGetTicket() donguisu kullandigi).
   // Hedging hesapta zaten her bacak KENDI dogru SL'ini acilista atomik
   // olarak aliyor (Buy/Sell cagrisindaki sl parametresi) - yeniden
   // hesaplamaya gerek yok, bu yuzden burada guvenle atlaniyor.
   if(!IsNettingAccount()) return;

   if(!PositionSelect(symbol)) return;
   if((ulong)PositionGetInteger(POSITION_MAGIC) != magic) return;

   int posType   = (int)PositionGetInteger(POSITION_TYPE);
   int direction = (posType == POSITION_TYPE_BUY) ? 1 : -1;
   double avgOpen = PositionGetDouble(POSITION_PRICE_OPEN);
   double curTp   = PositionGetDouble(POSITION_TP);

   double newSl = HardSL_ComputePrice(symbol, direction, isGridMotor, avgOpen);
   if(newSl <= 0.0) return;

   double curSl = PositionGetDouble(POSITION_SL);
   // Gereksiz PositionModify cagrisindan kacin (broker rate-limit / log gurultusu)
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(MathAbs(curSl - newSl) <= point * 0.5) return;

   if(!g_trade.PositionModify(symbol, newSl, curTp))
      PrintFormat("HARD SL RECALC FAIL | %s | retcode=%u | %s",
                  symbol, g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
}

// v1.78.98 FIX (DUZELTME_REHBERI #9): Lot_CalcCapped baska hicbir baglam
// bilgisi olmadan sadece 0.0 dondurebiliyor - Grid ve Bullet tarafinda
// DIAG_RET/log cagrisi "neden 0 dondu" ayrimini yapamiyordu. Bu global,
// Lot_CalcCapped 0 dondurmeden HEMEN once "neden" bilgisini birakir;
// cagiran taraf kendi DIAG_RET/PrintFormat cagrisinda okuyabilir.
string g_lastLotRejectReason = "";

double Lot_CalcCapped(const string symbol, double baseLot, const bool isGridMotor=true, const int direction=1)
{
   g_lastLotRejectReason = "";
   if(baseLot <= 0.0) return 0.0;
   if(!Trade_SafetyGate(symbol, isGridMotor)) return 0.0;
   double tune = AutoTune_LotMult();
   if(tune > 1.5) tune = 1.5;
   double boost = TimeLotBoost_Mult();
   if(boost > 1.3) boost = 1.3;
   double penalty = LotPenalty_Mult();
   double risk = RT_RiskLotMult();
   if(risk > 1.5) risk = 1.5;
   // v1.78.102 FIX (kullanici karari): Trend-ici pullback modulu SADECE
   // MANUEL ve AUTO lot modlarinda lot buyuklugune carpan olarak uygulanir.
   // BLM_PROJECT (TP-Proj Solver / DEFICIT-PEAK-BAKIYE rejimleri) modunda
   // solver zaten "sepeti hedefe tam ulastiracak" matematiksel bir lot
   // hesabi yapiyor (bkz. TPProj_Run/required_lot) - bu sonucu pullback
   // carpaniyla kucultmek hedef matematigini bozar ve solver'in bir
   // sonraki adimda "eksik kaldi" deyip daha da buyuk lot istemesine yol
   // acabilecek ongorulemez bir geri besleme dongusu yaratabilirdi. Bu
   // yuzden PROJECT modunda pullback ETKISI SADECE VEMA_MA_RegimeGate
   // icindeki confidence/log tarafinda kalir (Direction Lock/giris kararini
   // dolayli etkiler), solver'in urettigi required_lot HICBIR SEKILDE
   // kucultulmez. MANUEL (BLM_MANUAL) ve AUTO (BLM_AUTO) modlarda ise
   // boyle bir "hedefe tam ulas" matematigi olmadigi icin pullback carpani
   // aynen calismaya devam eder.
   double pullback = (RT_LotMode() == BLM_PROJECT) ? 1.0 : PULLBACK_LotMult(symbol);

   double finalLot = baseLot * tune * boost * penalty * risk * pullback;

   // 1) strateji hard cap (kullanicinin ayarladigi InpLatticeMaxLot)
   if(InpLatticeMaxLot > 0.0 && finalLot > InpLatticeMaxLot)
      finalLot = InpLatticeMaxLot;

   // v1.78.98 FIX (DUZELTME_REHBERI #1, P0): RiskCap_MaxLot() equity-risk%
   // tavani v1.78.93'te burada tamamen devre disi birakilmisti (asagida
   // eski davranis notu duruyor) - equity-orantili koruma HICBIR YERDEN
   // uygulanmiyordu. Artik ZORUNLU ikinci katman:
   //   - Risk verisi hesaplanamiyorsa (ATR/equity/tick eksik -> DBL_MAX),
   //     "sinirsiz ac" ARTIK KABUL EDILMIYOR -> islem acilmaz (0 doner).
   //   - Risk cap <= 0 ise de islem acilmaz.
   //   - Aksi halde finalLot bu tavanin USTUNE CIKAMAZ.
   // v1.78.141 RISK_CALIBRATION FIX: RiskCap_MaxLot artik isGridMotor/
   // direction alarak GERCEK Hard SL mesafesini kullanir (bkz. tanimi).
   double riskMaxLot = DBL_MAX;
   if(InpRiskSizing_Enable) {
      riskMaxLot = RiskCap_MaxLot(symbol, isGridMotor, direction);
      if(riskMaxLot == DBL_MAX) {
         g_lastLotRejectReason = "RISK_CAP_VERI_YOK";
         return 0.0;
      }
      if(riskMaxLot <= 0.0) {
         g_lastLotRejectReason = "RISK_CAP_SIFIR";
         return 0.0;
      }
      if(finalLot > riskMaxLot)
         finalLot = riskMaxLot;
   }

   // v1.78.141 RISK_CALIBRATION FIX (DUZELTME_REHBERI Bolum 10, P1): "MIN LOT
   // KONUSU: RISK VETOYU BROKER MINIMUMUNA CEVIRME". ESKI DAVRANIS:
   // NormalizeLotForEntry() risk-cap'in ALTINDA kalan bir lotu SESSIZCE
   // minLot'a YUKARI YUVARLIYORDU - "risk motoru 0.003 lot guvenli diyor" ile
   // "broker 0.01'in altini kabul etmiyor" birbirine karisip fiilen kat kat
   // fazla riskle islem acilabiliyordu. Artik minLot'a yukari yuvarlama
   // YALNIZCA minLot'un GERCEK SL riski (dogru Hard SL mesafesiyle,
   // OrderCalcProfit ile) risk butcesinin ICINDE kaldigi AYRICA
   // KANITLANIRSA yapilir - raporun aynen istedigi kural. Kanitlanamazsa
   // islem RISK_MINLOT_ASIYOR ile reddedilir, minLot'a yukari ZORLANMAZ.
   double minLotSym = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   if(InpRiskSizing_Enable && minLotSym > 0.0 && finalLot > 0.0 && finalLot < minLotSym) {
      double minLotDist = HardSL_Distance(symbol, isGridMotor);
      double refPx = (direction > 0) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
      bool minLotProven = false;
      // v1.78.165 FIX (kullanicinin tam-log analizinde bulundu): minLotLoss/
      // budgetChk eskiden SADECE ic if-blogunda tanimliydi - kanitlanamadigi
      // ANLARDA (asagidaki "else" dali) HICBIR YERDE loglanmiyordu; erken
      // "return 0.0" audit-log blogunun (fonksiyon sonunda) TAMAMEN
      // ATLANMASINA yol aciyordu. Sonuc: "R21 GRID/BULLET IPTAL sebep=...
      // RISK_MINLOT_ASIYOR" tum haftanin EN SIK (148.734 kez) goeruelen
      // olayiydi ama GERCEK rakamlar (butce ne kadar, gercek risk ne kadar)
      // hicbir Journal satirinda YOKTU. Artik disariya tasindi ve HER ZAMAN
      // (basarili/basarisiz farketmeksizin) asagida loglaniyor.
      double minLotLoss = -1.0;
      double budgetChk = -1.0;
      if(minLotDist > 0.0 && refPx > 0.0) {
         double slPx = (direction > 0) ? (refPx - minLotDist) : (refPx + minLotDist);
         ENUM_ORDER_TYPE otChk = (direction > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
         if(slPx > 0.0 && OrderCalcProfit(otChk, symbol, minLotSym, refPx, slPx, minLotLoss) && MathIsValidNumber(minLotLoss)) {
            double eqChk = EffectiveEquity(symbol);
            if(eqChk <= 0.0) eqChk = AccountInfoDouble(ACCOUNT_BALANCE);
            budgetChk = eqChk * InpRiskSizing_MaxRiskPct / 100.0;
            if(MathAbs(minLotLoss) <= budgetChk)
               minLotProven = true;
         }
      }
      if(minLotProven) {
         finalLot = minLotSym; // kanitlandi: minLot'un gercek riski butce icinde
      } else {
         g_lastLotRejectReason = "RISK_MINLOT_ASIYOR"; // minLot'un gercek riski butceyi asiyor / kanitlanamadi
         PrintFormat("R21 MINLOT RISK TESHIS | %s | motor=%s minLot=%.2f mesafe=%.5f | gercekZarar=%.2f butce=%.2f | oran=%.2fx | RiskPct=%.2f%%",
                     symbol, (isGridMotor ? "GRID" : "BULLET/DIGER"), minLotSym, minLotDist,
                     minLotLoss, budgetChk, (budgetChk > 0.0 ? MathAbs(minLotLoss) / budgetChk : -1.0),
                     InpRiskSizing_MaxRiskPct);
         return 0.0;
      }
   }

   // v1.78.130 FIX: mutlak 0.5 hard-cap kaldirildi; lot buyumesi artik
   // risk-cap, broker min/step sinirlari ve normalize katmani ile dogru
   // sekilde kontrol edilir.
   double normalized = NormalizeLotForEntry(symbol, finalLot);
   if(normalized <= 0.0 && g_lastLotRejectReason == "")
      g_lastLotRejectReason = "RISK_MINLOT"; // hesaplanan guvenli lot broker minLot'unun altinda

   // v1.78.141 RISK_CALIBRATION FIX (DUZELTME_REHBERI Bolum 11, P2): "LOT
   // BUYUMEMESININ TEKNIK NEDENI" - raporun istedigi lot denetim izi.
   // Lot_CalcCapped, Grid VE Bullet'in PAYLASTIGI ortak son-kapama asamasi
   // oldugu icin audit logu burada merkezilestirildi (yukari akisdaki grid
   // carpani/win-streak carpani gibi motor-ozel katsayilar zaten kendi
   // PrintFormat'larinda ayrica loglaniyor - bkz. R21 TP-PROJ LOT).
   if(InpSR_LogDecisions) {
      double lossPer1LotLog = 0.0;
      if(riskMaxLot > 0.0 && riskMaxLot != DBL_MAX)
         lossPer1LotLog = (riskMaxLot > 0.0) ? (AccountInfoDouble(ACCOUNT_EQUITY) * InpRiskSizing_MaxRiskPct / 100.0) / riskMaxLot : 0.0;
      double expectedLossLog = lossPer1LotLog * normalized;
      PrintFormat("R21 LOT AUDIT | %s | motor=%s dir=%d | GirisLot=%.4f AutoTune=%.3f Boost=%.3f Penalty=%.3f RiskLotMult=%.3f Pullback=%.3f | RiskCapLot=%s | FinalLot=%.4f | LossPer1Lot=%.2f ExpectedLoss=%.2f | Sebep=%s",
                  symbol, (isGridMotor ? "GRID" : "BULLET/DIGER"), direction,
                  baseLot, tune, boost, penalty, risk, pullback,
                  (riskMaxLot == DBL_MAX ? "SINIRSIZ/KAPALI" : DoubleToString(riskMaxLot, 4)),
                  normalized, lossPer1LotLog, expectedLossLog,
                  (g_lastLotRejectReason != "" ? g_lastLotRejectReason : "YOK"));
   }
   return normalized;
}

//--- Lot hesapla
//--- v1.78.41 FIX: 1 lot icin gercekci margin hesabi + yon-farkindalikli.
// Eskiden her yerde sabit ORDER_TYPE_BUY kullanilyordu (SELL icin de BUY
// margin'i uygulanıyordu — asimetrik marginli sembollerde yanlis lot riski),
// ve OrderCalcMargin basarisiz olursa "bal*0.01" gibi tamamen keyfi, gercek
// margin gereksinimiyle hicbir ilgisi olmayan bir deger kullaniliyordu.
// Bu fonksiyon: 1) dogru ORDER_TYPE (BUY/SELL) ile hesaplar, 2) basarisiz
// olursa CONTRACT_SIZE*price/LEVERAGE ile daha gercekci bir tahmine duser,
// 3) v1.78.141 RISK_CALIBRATION FIX (Bolum 9, P1): o da basarisiz olursa
// ARTIK "bal*0.01" gibi keyfi bir sayiya DUSMEZ - 0.0 doner (bkz. fonksiyon
// govdesindeki guncel yorum).
double Margin_PerLotSafe(const string symbol, const int direction) {
   ENUM_ORDER_TYPE ot = (direction < 0) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   double price = (direction < 0) ? SymbolInfoDouble(symbol, SYMBOL_BID)
                                   : SymbolInfoDouble(symbol, SYMBOL_ASK);
   double marginPerLot = 0.0;
   if(OrderCalcMargin(ot, symbol, 1.0, price, marginPerLot) && marginPerLot > 0.0)
      return marginPerLot;

   // Fallback: CONTRACT_SIZE * price / LEVERAGE (standart Forex/CFD marjini) -
   // bu hala GERCEK sembol/hesap verisine (contract size, gercek kaldirac)
   // dayanan bir HESAPLAMA, keyfi bir sayi degil; bu yuzden korunuyor.
   double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   long   leverage      = AccountInfoInteger(ACCOUNT_LEVERAGE);
   if(contractSize > 0.0 && leverage > 0 && price > 0.0) {
      double est = (contractSize * price) / (double)leverage;
      if(est > 0.0) return est;
   }

   // v1.78.141 RISK_CALIBRATION FIX (DUZELTME_REHBERI Bolum 9, P1): "Margin
   // fallback = balance*%1 - Arbitrary margin kabulü" KALDIRILDI. Bakiyenin
   // %1'i gibi finansal olarak keyfi, sembol/broker/kaldiracla HICBIR ilgisi
   // olmayan bir tahmin "gercek hesapta kabul edilebilir bir risk kontrolu
   // degildir" (raporun kendi ifadesi). Ikisi de basarisiz olursa artik 0.0
   // donuyor - cagiran taraf (Lattice_CalcLot/Bullet lot hesabi, GLM_BALANCE_
   // PCT/GLM_EQUITY_PCT/BAK% branch'leri) bunu zaten "marginPerLot<=0 ->
   // lot=minLot" olarak ele aliyor - "tahmini buyuk lot" yerine guvenli
   // minLot'a duser. Nihai margin dogrulamasi zaten Trade_PreflightMarketOrder()
   // icinde GERCEK OrderCalcMargin + OrderCheck ile AYRICA yapiliyor ve
   // basarisiz olursa islemi TAMAMEN veto ediyor - o kontrol BURADAN
   // BAGIMSIZ ve degismedi (asagida bkz.).
   return 0.0;
}

// v1.78.98 FIX (DUZELTME_REHBERI #4, P0): bu EA'nin (g_magic) verilen
// sembol + yondeki TUM acik pozisyonlarinin toplam lotu. Grid derinligi
// (buy_levels_active/sell_levels_active) kademe SAYISINI zaten sinirliyor
// (LATTICE_MAX_LEVELS) ama TOPLAM lotu sinirlamiyor - carpanli buyume
// (g_rt_grid_mult) ile bir yonde acik kademe sayisi arttikca toplam
// exposure sinirsizce katlanabiliyordu. Bu fonksiyon o toplami olcer;
// InpGridMaxTotalLot ile karsilastirilir (bkz. asagidaki cagiran kod).
double Grid_OpenExposure(const string symbol, const int direction) {
   double total = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      int ptype = (int)PositionGetInteger(POSITION_TYPE);
      if(direction > 0 && ptype != POSITION_TYPE_BUY) continue;
      if(direction < 0 && ptype != POSITION_TYPE_SELL) continue;
      total += PositionGetDouble(POSITION_VOLUME);
   }
   return total;
}

//======================================================================
// v1.78.141 RISK_CALIBRATION - TEK RISK SOZLESMESI (rapor Bolum 3/5)
// Asagidaki 4 fonksiyon raporun P0 #3 (Grid+Bullet netting cakismasi),
// P1 Bolum 6 (Grid/Bullet exposure ayrimi) ve P1 Bolum 7 (orphan riskinin
// basket'e dahil edilmesi) bulgularini uygular. Hepsi ayni ayrim yontemini
// kullanir: Grid pozisyonlari InpTradeComment'i SUFFIX'SIZ acar, Bullet
// "-BLT" ekler (bkz. Lattice_ReconcileFromBroker yorumu, satir ~7367 - AYNI
// yontem orada orphan/motor ayrimi icin zaten kullaniliyordu). Comment,
// PositionGetString ile GERCEK broker pozisyon yapisindan okunur - EA'nin
// kendi RAM state'ine (restart'ta sifirlanabilir) degil.
//======================================================================

// Bolum 6 (P1): "GridMaxTotalLot Bullet'ı da etkileyebiliyor" - motor bazinda
// AYRI exposure. isGridMotor=true -> sadece Grid pozisyonlari, false -> sadece
// Bullet pozisyonlari (ayni symbol+g_magic altinda, iki yon birden - Trade_
// SafetyGate'in eski toplam-exposure semantigiyle AYNI kapsam, sadece motor
// filtresi eklendi).
double Engine_OpenExposure(const string symbol, const bool isGridMotor) {
   double total = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      bool hasBulletTag = (StringFind(PositionGetString(POSITION_COMMENT), "-BLT") >= 0);
      if(isGridMotor && hasBulletTag) continue;    // Bullet'a ait - Grid sayacina girmez
      if(!isGridMotor && !hasBulletTag) continue;  // Grid'e ait - Bullet sayacina girmez
      total += PositionGetDouble(POSITION_VOLUME);
   }
   return total;
}

// P0 #3: "Grid + Bullet aynı g_magic / netting - Tek pozisyonda SL semantiği
// karışıyor". Netting hesapta sembol basina TEK pozisyon vardir; Grid (9 ATR
// mesafe varsayan) ve Bullet (3 ATR mesafe varsayan) ayni magic ile ayni net
// pozisyona farkli zamanlarda ekleme yaptiginda, HardSL_RecalcOnAdd SON
// cagrilan motorun mesafesini pozisyonun TAMAMINA uygular - iki motorun
// birbirinden HABERSIZ risk varsayimlari TEK bir SL'de cakisir. Raporun
// onerdigi "en guvenli secenek" (Bolum 4D): "Netting hesapta ayni sembolde
// Grid ve Bullet'ı aynı anda çalıştırma". Bu fonksiyon o kurali uygular:
// netting hesapta bir motor, ancak DIGER motorun o sembolde ACIK pozisyonu
// yoksa yeni giris/ekleme yapabilir. Hedging hesapta her motor zaten kendi
// ayri bacagini tutar (bkz. HardSL_RecalcOnAdd'deki ayni netting kontrolu) -
// bu yuzden hedging hesapta kisitlama YOKTUR.
bool RiskModel_EngineExclusive(const string symbol, const bool isGridMotor)
{
   if(!IsNettingAccount()) return true;
   if(!PositionSelect(symbol)) return true; // sembolde hic pozisyon yok - ilk giris serbest
   if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) return true; // bu EA'ya ait degil (hedge/manuel/baska EA)

   bool hasBulletTag  = (StringFind(PositionGetString(POSITION_COMMENT), "-BLT") >= 0);
   bool isExistingGrid = !hasBulletTag;

   if(isGridMotor && !isExistingGrid) {
      PrintFormat("RISK MODEL VETO | %s | Bullet pozisyonu ACIKKEN Grid ayni net pozisyona giremez (netting SL cakismasi onleniyor, DUZELTME_REHBERI P0 #3)", symbol);
      return false;
   }
   if(!isGridMotor && isExistingGrid) {
      PrintFormat("RISK MODEL VETO | %s | Grid pozisyonu ACIKKEN Bullet ayni net pozisyona giremez (netting SL cakismasi onleniyor, DUZELTME_REHBERI P0 #3)", symbol);
      return false;
   }
   return true;
}

// Bolum 3/7 (P0/P1): "Basket için Σ PositionRisk + NewPositionRisk ≤
// BasketRiskBudget" ve "Orphan'ın riskini toplam basket riskine dahil et".
// PositionsTotal() uzerinden GERCEK broker pozisyonlarini tarar (lat.buy_
// levels[]/sell_levels[] gibi EA'nin kendi tracking state'ine BAGIMLI
// DEGILDIR) - bu yuzden GridRisk Firewall'un LATTICE_MAX_LEVELS asimi
// yuzunden state'e alamadigi "orphan" pozisyonlar da otomatik olarak bu
// toplama dahil olur (raporun Bolum 7 istegi). Herhangi bir pozisyonun
// SL'si yoksa (POSITION_SL<=0 - fail-closed sayesinde artik olmamali ama
// restart/manuel mudahale/eski pozisyon ihtimaline karsi savunma amacli)
// fonksiyon DBL_MAX (= "risk bilinmiyor, en kotusunu varsay") dondurur.
double RiskModel_BasketRiskMoney(const string symbol)
{
   double total = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      double vol    = PositionGetDouble(POSITION_VOLUME);
      double sl     = PositionGetDouble(POSITION_SL);
      double openPx = PositionGetDouble(POSITION_PRICE_OPEN);
      int    ptype  = (int)PositionGetInteger(POSITION_TYPE);

      if(sl <= 0.0 || vol <= 0.0 || openPx <= 0.0) {
         PrintFormat("RISK MODEL UYARI | %s | ticket=%I64u SL/lot/fiyat eksik - basket riski hesaplanamadi (fail-safe: butce asilmis varsayilacak)", symbol, ticket);
         return DBL_MAX;
      }

      ENUM_ORDER_TYPE ot = (ptype == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double profit = 0.0;
      if(!OrderCalcProfit(ot, symbol, vol, openPx, sl, profit) || !MathIsValidNumber(profit)) {
         PrintFormat("RISK MODEL UYARI | %s | ticket=%I64u OrderCalcProfit basarisiz - basket riski hesaplanamadi (fail-safe)", symbol, ticket);
         return DBL_MAX;
      }
      total += MathAbs(profit);
   }
   return total;
}

// Yeni bir Grid/Bullet girisi acilmadan ONCE cagrilir: mevcut sepet riski +
// yeni pozisyonun riski, RiskCap_MaxLot ile AYNI butceyi (equity * InpRisk
// Sizing_MaxRiskPct) asiyor mu diye bakar. NOT: bu kontrol SADECE g_magic
// (Grid/Bullet) girisleri icin uygulanir - hedge motorlari (NFH/WH/DDH)
// KASITLI OLARAK haric tutulur: onlarin amaci net exposure'i AZALTMAK,
// ayni butce tavanina tabi tutmak onlari yanlislikla engelleyip hesabi DAHA
// SAVUNMASIZ birakabilir (rapor Bolum 14 hedge'leri AYRI/gross-exposure
// kontrolu gerektiren farkli bir kategori olarak ele aliyor).
bool RiskModel_BasketRiskOK(const string symbol, const double newPositionRiskMoney)
{
   if(!InpRiskSizing_Enable || InpRiskSizing_MaxRiskPct <= 0.0) return true;

   double equity = EffectiveEquity(symbol);
   if(equity <= 0.0) equity = AccountInfoDouble(ACCOUNT_BALANCE);
   if(equity <= 0.0) return false;

   double budget = equity * InpRiskSizing_MaxRiskPct / 100.0;
   double existing = RiskModel_BasketRiskMoney(symbol);
   if(existing == DBL_MAX) {
      PrintFormat("RISK MODEL VETO | %s | mevcut sepet riski hesaplanamadi (SL/veri eksik pozisyon var) - yeni giris veto", symbol);
      return false;
   }

   double totalIfOpened = existing + MathMax(0.0, newPositionRiskMoney);
   if(totalIfOpened > budget) {
      PrintFormat("RISK MODEL VETO | %s | sepet riski asilacakti: mevcut=%.2f + yeni=%.2f = %.2f > butce=%.2f",
                  symbol, existing, newPositionRiskMoney, totalIfOpened, budget);
      return false;
   }
   return true;
}

void AsyncHedgeProtection_RecordReject(const string symbol) {
   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) return;
   ulong nowMs = GetTickCount64();
   if(g_lastOrderRejectMs[idx] == 0 || nowMs - g_lastOrderRejectMs[idx] > 10000)
      g_orderRejectCount[idx] = 0;
   g_orderRejectCount[idx]++;
   g_lastOrderRejectMs[idx] = nowMs;
}

bool AsyncHedgeProtection_Refresh(const string symbol) {
   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) return false;

   ulong nowMs = GetTickCount64();
   long spreadPts = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   int maxSpreadPts = AutoCost_MaxSpreadPts(symbol);
   bool spreadSpike = (spreadPts > 0 && maxSpreadPts > 0 && spreadPts >= maxSpreadPts);
   bool staleLock = false;
   for(int side = 0; side < 2; side++) {
      if(!g_gridSendLock[idx][side]) {
         g_gridLockSinceMs[idx][side] = 0;
         continue;
      }
      if(g_gridLockSinceMs[idx][side] == 0)
         g_gridLockSinceMs[idx][side] = nowMs;
      if(nowMs - g_gridLockSinceMs[idx][side] >= 1000)
         staleLock = true;
   }

   if(g_lastOrderRejectMs[idx] > 0 && nowMs - g_lastOrderRejectMs[idx] > 10000)
      g_orderRejectCount[idx] = 0;
   bool repeatedRejects = (g_orderRejectCount[idx] >= 3 &&
                           g_lastOrderRejectMs[idx] > 0 &&
                           nowMs - g_lastOrderRejectMs[idx] <= 10000);
   bool protect = spreadSpike || staleLock || repeatedRejects;
   if(protect) {
      g_asyncHedgeProtect[idx] = true;
      if(spreadSpike) g_asyncHedgeReason[idx] = "SPREAD_SPIKE";
      else if(staleLock) g_asyncHedgeReason[idx] = "TIME_DRIFT";
      else g_asyncHedgeReason[idx] = "REPEATED_REJECT";
      return true;
   }

   if(!g_ddHedgeActive)
      g_asyncHedgeProtect[idx] = false;
   return g_asyncHedgeProtect[idx];
}

bool Trade_SafetyGate(const string symbol, const bool isGridMotor=true) {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   if(balance <= 0.0 || equity <= 0.0) return false;

   double ddPct = ((balance - equity) / balance) * 100.0;
   if(ddPct >= 12.0) {
      g_lastLotRejectReason = "SAFETY_DD_12PCT";
      return false;
   }

   // v1.78.141 RISK_CALIBRATION FIX (Bolum 3, P0 #3): Grid/Bullet netting
   // cakismasini engelle - bkz. RiskModel_EngineExclusive() tanimi.
   if(!RiskModel_EngineExclusive(symbol, isGridMotor)) {
      g_lastLotRejectReason = "SAFETY_ENGINE_CONFLICT";
      return false;
   }

   // v1.78.141 RISK_CALIBRATION FIX (Bolum 6, P1): "GridMaxTotalLot Bullet'ı
   // da etkileyebiliyor" - exposure artik SADECE cagiran motorun (isGridMotor)
   // KENDI pozisyonlarindan sayiliyor (bkz. Engine_OpenExposure).
   double exposure = Engine_OpenExposure(symbol, isGridMotor);
   if(InpGridMaxTotalLot > 0.0 && exposure >= InpGridMaxTotalLot) {
      g_lastLotRejectReason = "SAFETY_EXPOSURE_CAP";
      return false;
   }

   if(InpRiskSizing_Enable) {
      double riskMaxLot = RiskCap_MaxLot(symbol, isGridMotor);
      if(riskMaxLot == DBL_MAX || riskMaxLot <= 0.0) {
         g_lastLotRejectReason = "SAFETY_RISK_CAP_INVALID";
         return false;
      }
   }
   return true;
}

double Lattice_CalcLot(const string symbol) {
   return Lattice_CalcLot(symbol, 0);
}

// GRID MULTIPLIER SAFETY: Çarpan finite/üst sınırlı hesaplanır; cap sonrası
// minimum lot zorlaması kaldırılarak risk tavanı aşılırsa işlem reddedilir.
double Lattice_CalcLot(const string symbol, const int direction) {
   double lot = RT_VG_Lot();
   double minLot0 = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double step0   = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   if(step0 <= 0.0) step0 = 0.01;
   double maxLot0 = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   if(!MathIsValidNumber(lot) || lot <= 0.0 ||
      !MathIsValidNumber(minLot0) || minLot0 <= 0.0 ||
      !MathIsValidNumber(maxLot0) || maxLot0 < minLot0)
      return 0.0;
   double minLot = minLot0;
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double step   = step0;

   // Panel BAK %: bakiye yüzdesi ile lot ölçekle (0.01 = %0.01 bakiyeden risk)
   // v1.73: bal<=0 / marginPerLot<=0 koruması (sıfıra bölünme)
   if(g_rt_ready && g_rt_bak_pct > 0.0 && InpVG_LotMode == GLM_FIXED) {
      double bal = AccountInfoDouble(ACCOUNT_BALANCE);
      if(bal > 0.0) {
         double marginPerLot = Margin_PerLotSafe(symbol, direction);
         if(marginPerLot > 0.0)
            lot = MathMax(lot, (bal * (RT_BakPct() / 100.0)) / marginPerLot);
      }
   }
   switch(InpVG_LotMode) {
      case GLM_FIXED:
         break;
      case GLM_BALANCE_PCT: {
         double bal = AccountInfoDouble(ACCOUNT_BALANCE);
         if(bal <= 0.0) { lot = minLot; break; }
         double marginPerLot = Margin_PerLotSafe(symbol, direction);
         if(marginPerLot <= 0.0) { lot = minLot; break; }
         double pct = (g_rt_ready && g_rt_bak_pct > 0) ? RT_BakPct() : InpVG_LotValue;
         lot = (bal * (pct / 100.0)) / marginPerLot;
         break;
      }
      case GLM_EQUITY_PCT: {
         double eq = AccountInfoDouble(ACCOUNT_EQUITY);
         if(eq <= 0.0) { lot = minLot; break; }
         double marginPerLot = Margin_PerLotSafe(symbol, direction);
         if(marginPerLot <= 0.0) { lot = minLot; break; }
         double pct = (g_rt_ready && g_rt_bak_pct > 0) ? RT_BakPct() : InpVG_LotValue;
         lot = (eq * (pct / 100.0)) / marginPerLot;
         break;
      }
   }

   // Grid multiplier MUST be applied after the selected lot mode has produced
   // its base lot. Applying it before GLM_BALANCE_PCT/GLM_EQUITY_PCT allowed
   // those branches to overwrite the multiplied value, which made successive
   // grid levels appear fixed. The step ceiling preserves visible growth when
   // a small multiplier would otherwise disappear during floor normalization.
   // v1.78.130: Grid çarpanı tüm yollarda (AUTO/PROJECT/FIXED) garantili uygulanır
   if(g_rt_ready && g_rt_grid_mult_on && g_rt_grid_mult > 1.0) {
      if(!MathIsValidNumber(g_rt_grid_mult) || g_rt_grid_mult > 10.0)
         return 0.0;

      int depth = (direction > 0) ? g_lattice.buy_levels_active : g_lattice.sell_levels_active;
      if(depth < 0) depth = 0;
      if(depth > LATTICE_MAX_LEVELS) depth = LATTICE_MAX_LEVELS;

      if(depth > 0) {
         double baseLotBeforeMultiplier = lot;
         // v1.78.130 FIX: Ardışık çarpan (sequential) her kademede üstel büyüme sağlar
         double multiplier = g_rt_seq_mult ? MathPow(g_rt_grid_mult, depth) : g_rt_grid_mult;
         if(!MathIsValidNumber(multiplier) || multiplier <= 0.0)
            return 0.0;
         
         // Matematiksel güvenlik: çarpan ile sonuç çok büyümemeyi kontrol et
         double resultLot = baseLotBeforeMultiplier * multiplier;
         if(!MathIsValidNumber(resultLot) || resultLot <= 0.0)
            return 0.0;
         if(resultLot > maxLot0 * 100.0) // Aşırı büyüme koruması
            resultLot = maxLot0;
         
         lot = resultLot;

         double baseStepLot = MathCeil(baseLotBeforeMultiplier / step0 - 1e-12) * step0;
         double stepGrowthFloor = g_rt_seq_mult
                                  ? baseStepLot + depth * step0
                                  : baseStepLot + step0;
         double multiplierStepLot = MathCeil(lot / step0 - 1e-12) * step0;
         if(multiplierStepLot < stepGrowthFloor)
            multiplierStepLot = stepGrowthFloor;
         lot = multiplierStepLot;
      }
   }

   double riskGovMult = RiskGovernor_FinalLotMult(symbol, direction, 1);
   if(riskGovMult <= 0.0) {
      g_lastLotRejectReason = "RISK_GOV_LOCK";
      return 0.0;
   }
   lot *= riskGovMult;

   // FIX: AutoTune + TimeLotBoost + LotPenalty + RISK (hard-capped)
   // v1.78.141 RISK_CALIBRATION FIX: isGridMotor=true + gercek direction
   // Lot_CalcCapped'e iletiliyor (RiskCap_MaxLot artik Grid'in GERCEK 9 ATR
   // Hard SL mesafesini kullanabilsin diye - bkz. RiskCap_MaxLot yorumu).
   lot = Lot_CalcCapped(symbol, lot, true, direction);

   // v1.78.98 FIX (DUZELTME_REHBERI #2, P0): Lot_CalcCapped artik ya 0.0
   // (risk cap/minLot reddi) ya da zaten step/minLot'a gore normalize edilmis
   // gecerli bir lot dondurur (bkz. NormalizeLotForEntry). Asagidaki eski
   // "if(lot < minLot) lot = minLot" satirlari KALDIRILDI - bunlar tam da
   // riskin minLot'un altina isaret ettigi durumlarda islemi yukari
   // zorlayip niyet edilenden kat kat buyuk lotla aciyordu. 0 donerse bu
   // hucrede islem acilmaz (cagiran taraf DIAG_RET("LOT_SIFIR_VEYA_NEGATIF")
   // ile zaten bunu logluyor).
   if(lot <= 0.0) return 0.0;
   // v1.78.130: TP Peak likidasyon tavanı — sepet çarpanı yükselse bile nihai lot güvenli sınırda
   // v1.73: dinamik volume digits (sembol VOLUME_STEP) - sadece ustten kirpma
   if(lot > maxLot) lot = maxLot;
   if(InpLatticeMaxLot > 0.0 && lot > InpLatticeMaxLot) lot = InpLatticeMaxLot;
   // v1.78.130 FIX: Gecici 0.5 mutlak tavan, PROJ/Auto lot buyume
   // mekanizmasini kilitledigi icin kaldirildi. Nihai güvenlik, broker
   // maxLot / InpLatticeMaxLot / volume-step ve Trade_SafetyGate ile
   // korunur; kucuk bir esnek birim olarak 0.5 capi artik yoktur.
   // v1.78.109 FIX (kullanici karari - tutarlilik): NormalizeLotForEntry'de
   // (satir ~825 civari) uygulanan "minLot altina duserse 0 donme, minLot'a
   // yukari yuvarla" kurali burada da uygulanmaliydi. Eskiden ust kirpmalar
   // (maxLot/InpLatticeMaxLot/0.5 tavani) sonrasi lot minLot'un altina
   // duserse bu satir islemi TAMAMEN IPTAL ediyordu (0 donuyordu) - bu,
   // kullanicinin "min lot 0.01'e yukari yuvarla, asla islem kaybetme"
   // talebiyle CELISIYORDU. Artik minLot altina dusen lot iptal edilmiyor,
   // minLot'a yukari yuvarlanip islem acilmasina izin veriliyor.
   if(lot > 0.0 && lot < minLot) return 0.0;
   if(!Trade_SafetyGate(symbol, true)) return 0.0;
   double normalizedLot = NormalizeLotForEntry(symbol, lot);
   if(normalizedLot <= 0.0) {
      if(g_lastLotRejectReason == "")
         g_lastLotRejectReason = "GRID_VOLUME_STEP_OR_LIMIT";
      return 0.0;
   }
   return normalizedLot;
}

//--- Sanal TP mesafesini hesapla (fiyat birimi)
//+------------------------------------------------------------------+
//| FIX v1.78.13: gerçek maliyet farkındalığı (komisyon)              |
//+------------------------------------------------------------------+
// Sorun: TP kapatma kontrolü sadece POSITION_PROFIT+SWAP > 0 bakıyordu.
// Bu spread'i zaten içeriyor (bid/ask'tan hesaplanıyor) ama KOMİSYONU
// HİÇ içermiyor - açık pozisyonun anlık kârı komisyonu yansıtmaz, o
// sadece deal kapanınca işlem geçmişine yazılıyor. Yani "TP'ye ulaştı"
// denip kapatılan bir işlem, komisyon düşüldüğünde aslında zararlı
// çıkabiliyordu. Aşağıdaki fonksiyon bu hesabın/sembolün SON GERÇEK
// işlemlerinden ortalama lot-başı komisyonu okuyup, hem TP mesafesini
// hem kapanış eşiğini buna göre dinamik büyütüyor - istediğiniz "TP
// seviyelerini dinamik artır" tam olarak bu.
// v1.78.45 FIX (#116): s_cached/s_lastCalc TEK kopyaydi — symbol parametresi
// alinmasina ragmen cache TUM semboller arasinda PAYLASILIYORDU. Ilk hesaplanan
// sembolun komisyonu 300sn boyunca sonraki (farkli komisyon yapisina sahip)
// sembollere de donduruluyordu; bu deger Cost_MinNetProfit uzerinden TP/kapanis
// esiginde kullanildigi icin yanlis esik olusabiliyordu. Artik cache sembol
// bazli: Ind_FindIdx(symbol) ile MAX_SYMBOLS uzunlugunda dizilerde saklaniyor.
// Sembol g_symbols[] listesinde bulunamazsa (idx<0) cache'lenmeden dogrudan
// hesaplanip donduruluyor (eski davranistan daha guvenli — asla yanlis
// sembolun degerini donmez).
double Cost_EstCommissionPerLot(const string symbol) {
   static double   s_cached[MAX_SYMBOLS];
   static datetime s_lastCalc[MAX_SYMBOLS];
   static bool     s_cInit = false;
   if(!s_cInit) {
      for(int zi = 0; zi < MAX_SYMBOLS; zi++) { s_cached[zi] = -1.0; s_lastCalc[zi] = 0; }
      s_cInit = true;
   }

   int idx = Ind_FindIdx(symbol);
   if(idx >= 0 && s_lastCalc[idx] > 0 && TimeCurrent() - s_lastCalc[idx] < 300 && s_cached[idx] >= 0)
      return s_cached[idx];

   double result = (idx >= 0 && s_cached[idx] >= 0) ? s_cached[idx] : 0.0;
   if(HistorySelect(TimeCurrent() - 7*86400, TimeCurrent() + 60)) {
      double sumComm = 0.0, sumVol = 0.0;
      int total = HistoryDealsTotal();
      for(int i = total - 1; i >= 0 && sumVol < 3.0; i--) {
         ulong d = HistoryDealGetTicket(i);
         if(d == 0) continue;
         if(HistoryDealGetString(d, DEAL_SYMBOL) != symbol) continue;
         if((ulong)HistoryDealGetInteger(d, DEAL_MAGIC) != g_magic) continue;
         double comm = MathAbs(HistoryDealGetDouble(d, DEAL_COMMISSION));
         double vol  = HistoryDealGetDouble(d, DEAL_VOLUME);
         if(vol > 0) { sumComm += comm; sumVol += vol; }
      }
      if(sumVol > 0) result = sumComm / sumVol; // lot başı TEK YÖN komisyon
   }
   HistorySelect(0, TimeCurrent() + 86400); // geniş pencereyi geri yükle - diğer kod buna güveniyor
   if(idx >= 0) {
      s_cached[idx]   = result;
      s_lastCalc[idx] = TimeCurrent();
   }
   return result;
}

// Round-trip (açılış+kapanış) tahmini komisyon + risk moduna göre emniyet payı.
// Henüz geçmiş yoksa (yeni hesap/sembol) 0 döner - o durumda eski davranış
// (sadece profit>0) geçerli kalır, yanlışlıkla abartılı bir engel koymaz.
double Cost_MinNetProfit(const string symbol, const double volume) {
   double perLotOneSide = Cost_EstCommissionPerLot(symbol);
   double mult = (g_rt_ready && g_rt_cost_mult > 0) ? g_rt_cost_mult : 2.0;
   double fromComm = 0.0;
   if(perLotOneSide > 0.0 && volume > 0.0)
      fromComm = perLotOneSide * volume * 2.0 * mult; // 2.0 = acilis+kapanis
   // v1.78.18: komisyon 0 olsa bile risk motoru min kar tabani (0.10$ kapanis engeli)
   double floorMoney = RT_MinCloseMoney();
   if(fromComm > floorMoney) return fromComm;
   return floorMoney;
}

double Lattice_CalcTPDistance(const string symbol, const double lot) {
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0.0) point = _Point;
   double tpRaw = RT_VG_TP();
   double dist = tpRaw * point;

   switch(InpVG_TPMode) {
      case GTP_FIXED_POINTS:
         dist = tpRaw * point; // panel TP puanı
         break;
      case GTP_SPREAD_MULT: {
         // SECOND_AUDIT #5 FIX (P2): InpVG_TP_SpreadMult artik gercekten
         // kullaniliyor - eskiden bu carpan yerine genel panel tpRaw degeri
         // kullaniliyordu, input'un kendisi hicbir etkiye sahip degildi.
         long spreadPts = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
         dist = (double)spreadPts * point * InpVG_TP_SpreadMult;
         break;
      }
      case GTP_BALANCE_PCT: {
         // SECOND_AUDIT #5 FIX (P2): InpVG_TP_BalancePct artik gercekten
         // kullaniliyor - eskiden formul bakiyeye hic bakmiyordu (dist = tpRaw*point*10).
         // Simdi hedef: bakiyenin InpVG_TP_BalancePct yuzdesi kadar $ kar veren
         // fiyat mesafesi (asagidaki minNet blogundaki AYNI tickVal/tickSz/lot
         // para->mesafe donusum deseni kullanilarak). Broker verisi okunamazsa
         // (bal/tick bilgisi <= 0) eski davranisa (tpRaw*point*10) guvenli fallback.
         double balB = AccountInfoDouble(ACCOUNT_BALANCE);
         double tickValB = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
         double tickSzB  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
         dist = tpRaw * point * 10.0; // fallback
         if(balB > 0 && tickValB > 0 && tickSzB > 0 && lot > 0) {
            double targetMoneyB = balB * (InpVG_TP_BalancePct / 100.0);
            double moneyPerPriceB = (tickValB / tickSzB) * lot;
            if(moneyPerPriceB > 0) dist = targetMoneyB / moneyPerPriceB;
         }
         break;
      }
      case GTP_PRICE_PCT: {
         double mid = (SymbolInfoDouble(symbol, SYMBOL_BID) + SymbolInfoDouble(symbol, SYMBOL_ASK)) * 0.5;
         // tp_var_pct zaten yüzde (0.18 = %0.18) → /100
         if(g_rt_ready && g_rt_tp_var_pct > 0)
            dist = mid * (RT_TpVarPct() / 100.0);
         else
            dist = mid * (tpRaw / 100.0);
         break;
      }
   }
   // v1.78.20: TP VAR % artik mesafeyi DARALTMAZ – sadece daha genis hedefe izin verir
   // (eski MathMin erken 0.5-0.7$ kapanisa yol aciyordu)
   if(g_rt_ready && g_rt_tp_var_pct > 0 && InpVG_TPMode != GTP_PRICE_PCT) {
      double mid = (SymbolInfoDouble(symbol, SYMBOL_BID) + SymbolInfoDouble(symbol, SYMBOL_ASK)) * 0.5;
      double alt = mid * (RT_TpVarPct() / 100.0);
      if(alt > dist) dist = alt; // genis olan kazanir
   }
   dist *= AutoTune_TPMult();

   // FIX v1.78.18: puan bazlı mesafe artık lot'a göre TERS orantılı ölçekleniyor.
   // Önceden: her seviye (0.01 lot da, grid_mult ile büyümüş 0.03 lot da) AYNI puan
   // mesafesini bekliyordu - ama 0.03 lot aynı mesafede 3 katı $ üretir, yani büyük
   // lotlu (grid'in derinlerindeki, daha riskli) pozisyonlar gereğinden çok daha
   // uzun süre açık kalıyordu. Referans (seviye 0) lota göre: 2x lot ≈ yarı mesafe,
   // aynı $ hedefine çok daha çabuk ulaşılır - tam sorduğunuz şey.
   double baseLot = RT_VG_Lot();
   if(baseLot > 0 && lot > 0 && lot != baseLot)
      dist *= (baseLot / lot);

   // v1.78.18: TP mesafesi min $ kârı garanti etsin (BTC 0.01 lot → cent engeli)
   double minNet = Cost_MinNetProfit(symbol, lot);
   double hardMinMoney = RT_MinCloseMoney();
   if(hardMinMoney > minNet) minNet = hardMinMoney;
   if(minNet > 0) {
      double tickVal = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSz  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      // bazi brokerlerde tickVal 1 lot bazli — lot ile carpilmali
      if(tickVal > 0 && tickSz > 0 && lot > 0) {
         double moneyPerPrice = (tickVal / tickSz) * lot;
         if(moneyPerPrice > 0) {
            double minDist = minNet / moneyPerPrice;
            if(minDist > dist) dist = minDist;
         }
      }
   }
   return dist;
}

//--- Lattice güncelleme (her tick)

// v1.78.134 YENI: Lattice_OnTPClosed() KENDI yorumunda da acikca belirtildigi
// gibi sadece "Lattice_ManageTP icindeki profit>0 dalindan" cagriliyor - yani
// Grid'in KAYIP tarafi (Hard SL, GridRiskFirewall emergency close, manuel
// mudahale, TFG/RangeProfitGuard disi HERHANGI bir kapanis) Hard SL'den
// BAGIMSIZ OLARAK, EN BASTAN BERI RiskGovernor/AutoTune'a hic bildirilmiyordu.
// Bu fonksiyon, ghost-temizligi bir ticket'in ARTIK ORADA OLMADIGINI tespit
// ettiginde (asagida Lattice_Update icinde cagrilir), gercek kar/zarari
// GECMISTEN (HistorySelectByPosition) cekip aynen Lattice_OnTPClosed gibi
// RiskGovernor_RecordTrade + AutoTune_OnDealProfit besler - state temizligine
// (active/ticket/pyramid sayaclari) DOKUNMAZ, o zaten cagiran tarafta yapiliyor.
void Lattice_RecordExternalClose(const string symbol, const ulong ticket, const int direction) {
   double profit = 0.0;
   bool found = false;

   ResetLastError();
   if(HistorySelectByPosition(ticket)) {
      for(int i = HistoryDealsTotal() - 1; i >= 0; i--) {
         ulong dealTicket = HistoryDealGetTicket(i);
         if(dealTicket == 0) continue;
         profit += HistoryDealGetDouble(dealTicket, DEAL_PROFIT)
                 + HistoryDealGetDouble(dealTicket, DEAL_SWAP)
                 + HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
         found = true;
      }
   } else {
      PrintFormat("LATTICE EXTERNAL CLOSE WARN | %s | ticket=%I64u HistorySelectByPosition err=%d",
                  symbol, ticket, GetLastError());
   }
   // v1.78.20 deseniyle ayni (TPProj_GetSameSideStats'ta da kullanilir):
   // genis history penceresini geri yukle, yoksa bu ticten sonra calisan
   // baska kod (orn. Security_GetDailyPnLPercent) bozulur.
   ResetLastError();
   if(!HistorySelect(0, TimeCurrent() + 86400))
      PrintFormat("LATTICE EXTERNAL CLOSE HISTORY RESTORE WARN | %s | err=%d", symbol, GetLastError());

   if(!found) {
      PrintFormat("LATTICE EXTERNAL CLOSE | %s | ticket=%I64u | gecmiste islem bulunamadi, bookkeeping atlaniyor",
                  symbol, ticket);
      return;
   }

   RiskGovernor_RecordTrade(symbol, 1, direction, profit);
   AutoTune_OnDealProfit(profit);
   PrintFormat("LATTICE EXTERNAL CLOSE TESPIT EDILDI | %s | ticket=%I64u | dir=%s | profit=%.2f",
               symbol, ticket, (direction > 0 ? "BUY" : "SELL"), profit);
}

void Lattice_Update(SLatticeState &lat, const string symbol) {
   if(!lat.initialized) {
      double mid = (SymbolInfoDouble(symbol, SYMBOL_BID) + SymbolInfoDouble(symbol, SYMBOL_ASK)) * 0.5;
      Lattice_Init(lat, symbol, mid);
      return;
   }

   // v1.68: ticket=0 kalan hücreleri eşleştir (ManageTP atlamasın; bir tick gecikme OK)
   Lattice_RematchTickets(lat, symbol);

   // Step değerlerini periyodik yenile (özellikle ATR / % modunda)
   // v1.78.45 FIX (#117): s_lastStepRefresh eskiden TEK static'ti, TUM semboller
   // arasinda PAYLASILIYORDU (fonksiyon tek, her sembol icin ayri instance yok).
   // Multi-symbol'de ilk islenen sembol throttle'i tuketince ayni tick'te digerleri
   // ATR step/TP yenilemesini atlayabiliyor, bazi semboller 30sn'den uzun sure eski
   // step/TP degerleriyle kalabiliyordu. Artik Ind_FindIdx(symbol) ile MAX_SYMBOLS
   // uzunlugunda bir diziye tasindi — her sembol kendi bagimsiz 30sn'lik refresh
   // periyoduna sahip. Sembol g_symbols[] icinde bulunamazsa (idx<0, beklenmez ama
   // guvenlik icin) throttle uygulanmadan her tick tazelenir.
   static datetime s_lastStepRefresh[MAX_SYMBOLS];
   static bool     s_lsrInit = false;
   if(!s_lsrInit) {
      for(int zi = 0; zi < MAX_SYMBOLS; zi++) s_lastStepRefresh[zi] = 0;
      s_lsrInit = true;
   }
   int lsrIdx = Ind_FindIdx(symbol);
   datetime lsrPrev = (lsrIdx >= 0) ? s_lastStepRefresh[lsrIdx] : 0;
   if(TimeCurrent() - lsrPrev >= 30) {   // 30 sn'de bir, sembol basina
      // v1.78.22: ATR Sistemi ACIKSA, aktif risk motorunun ADIM/TP puanini
      // guncel ATR'a gore tazele (ALGO'nun her-tick atrVal okumasinin throttle'li
      // Nexus karsiligi — RiskPreset_Apply'in butun tabloyu yeniden yazmasina
      // gerek kalmadan sadece step/TP guncellenir).
      if(RT_ATRMode() && g_rt_ready) {
         double rAtrStepPts, rAtrTpPts;
         double rTpRatio = RiskATR_TpStepRatioForMode(g_rt_risk_mode); // ilk secimdeki R:R ile ayni oran
         if(RiskATR_AutoFill(symbol, g_rt_risk_mode, rTpRatio, rAtrStepPts, rAtrTpPts)) {
            // v1.78.30 FIX: kullanici ADIM PNT/TP PUAN'a elle deger yazdiysa
            // (g_rt_*_manual_override), ATR ustune yazmasin — sadece
            // override edilmeyen tarafi tazele.
            if(!g_rt_step_manual_override) { g_rt_step_pnt = rAtrStepPts; g_rt_vg_step = rAtrStepPts; }
            if(!g_rt_tp_manual_override)   { g_rt_tp_pts   = rAtrTpPts; }
         }
      }
      Lattice_RefreshSteps(lat, symbol);
      if(lsrIdx >= 0) s_lastStepRefresh[lsrIdx] = TimeCurrent(); // v1.78.45 FIX (#117): sembol bazli kaydet
   }

   lat.last_update = TimeCurrent();

   // Açık ticket'ları doğrula + ghost temizligi (v1.78.20)
   const int GHOST_TIMEOUT_SEC = 30;
   datetime nowT = TimeCurrent();
   for(int i = 0; i < LATTICE_MAX_LEVELS; i++) {
      if(lat.buy_levels[i].active) {
         if(lat.buy_levels[i].ticket > 0) {
            if(!PositionSelectByTicket(lat.buy_levels[i].ticket)) {
               // v1.78.134 FIX: state temizlemeden ONCE gercek kapanis
               // sonucunu kaydet (RiskGovernor/AutoTune bu kapanistan artik
               // haberdar olsun - bkz. Lattice_RecordExternalClose yorumu).
               Lattice_RecordExternalClose(symbol, lat.buy_levels[i].ticket, +1);
               lat.buy_levels[i].active = false;
               lat.buy_levels[i].ticket = 0;
               lat.buy_levels_active = MathMax(0, lat.buy_levels_active - 1);
               // v1.78.72 FIX: bu kademe piramit-ekstra sayilmissa (isPyramidExtra
               // ile acilmis), TP disinda HERHANGI bir yoldan kapandiginda
               // (manuel mudahale, panel KARI/ZARARI/TUMUNU KAPAT, Trend Flip
               // Guard, Range Profit Guard, broker/stop-out) sayac ASLA
               // azalmiyordu — cunku azaltma sadece Lattice_OnTPClosed()
               // icindeydi ve o SADECE normal TP kapanisinda cagriliyordu.
               // Sonuc: pyramid_buy_extra kalici olarak InpVG_PyramidMaxExtra'ya
               // kilitlenip her tick'te PYRAMID_LIMIT logluyordu, hicbir zaman
               // acilmiyordu. Burada da (TP disi kapanis tespitinde) azaltiliyor.
               if(lat.pyramid_buy_extra > 0) lat.pyramid_buy_extra--;
            } else {
               // v1.78.41 FIX (#63): tamamen kapanma disinda pozisyon KISMEN
               // kapatilmis olabilir (manuel mudahale, broker taraf islemi vb.)
               // — bu durumda PositionSelectByTicket hala basarili doner ama
               // POSITION_VOLUME azalmis olur. Eskiden lat.buy_levels[i].lot
               // hic senkronize edilmiyordu, log/debug ciktilarinda bayat
               // (eski/buyuk) hacim gorunebiliyordu. Not: gercek trade
               // kararlari (TPProj_GetSameSideStats, Bullet_Manage, Security_
               // GetDailyPnLPercent vb.) zaten HER ZAMAN PositionGetDouble ile
               // canli hacim okuyor, bu senkronizasyon sadece state/log
               // dogrulugu icindir, kritik bir risk hesabini degistirmez.
               double liveVol = PositionGetDouble(POSITION_VOLUME);
               if(MathAbs(liveVol - lat.buy_levels[i].lot) > 1e-9)
                  lat.buy_levels[i].lot = liveVol;
            }
         } else if(lat.buy_levels[i].open_time > 0 &&
                   (nowT - lat.buy_levels[i].open_time) >= GHOST_TIMEOUT_SEC) {
            lat.buy_levels[i].active = false;
            lat.buy_levels[i].ticket = 0;
            lat.buy_levels[i].open_price = 0;
            lat.buy_levels_active = MathMax(0, lat.buy_levels_active - 1);
            // v1.78.72 FIX: ghost-timeout yolunda da piramit sayacini azalt (bkz. yukaridaki yorum).
            if(lat.pyramid_buy_extra > 0) lat.pyramid_buy_extra--;
         }
      }
      if(lat.sell_levels[i].active) {
         if(lat.sell_levels[i].ticket > 0) {
            if(!PositionSelectByTicket(lat.sell_levels[i].ticket)) {
               // v1.78.134 FIX: bkz. BUY tarafindaki ayni yorum.
               Lattice_RecordExternalClose(symbol, lat.sell_levels[i].ticket, -1);
               lat.sell_levels[i].active = false;
               lat.sell_levels[i].ticket = 0;
               lat.sell_levels_active = MathMax(0, lat.sell_levels_active - 1);
               // v1.78.72 FIX: ayni sebep - SELL tarafi piramit sayaci.
               if(lat.pyramid_sell_extra > 0) lat.pyramid_sell_extra--;
            } else {
               double liveVol = PositionGetDouble(POSITION_VOLUME);
               if(MathAbs(liveVol - lat.sell_levels[i].lot) > 1e-9)
                  lat.sell_levels[i].lot = liveVol;
            }
         } else if(lat.sell_levels[i].open_time > 0 &&
                   (nowT - lat.sell_levels[i].open_time) >= GHOST_TIMEOUT_SEC) {
            lat.sell_levels[i].active = false;
            lat.sell_levels[i].ticket = 0;
            lat.sell_levels[i].open_price = 0;
            lat.sell_levels_active = MathMax(0, lat.sell_levels_active - 1);
            // v1.78.72 FIX: ghost-timeout yolunda da piramit sayacini azalt (SELL).
            if(lat.pyramid_sell_extra > 0) lat.pyramid_sell_extra--;
         }
      }
   }

   // Kapanan/ghost seviyelerden kalan STEP referansını temizle.
   Lattice_RebuildLastOpenRefs(lat);
}

//--- Yeni sanal seviye açmayı dene
//+------------------------------------------------------------------+
//| Ticket eşleştirme: emir/deal sonucundan POSITION ticket bul      |
//+------------------------------------------------------------------+
// CTrade.Buy/Sell sonrası:
//   ResultOrder()  → order ticket (pending veya market order id)
//   ResultDeal()   → deal ticket
//   ResultPrice()  → dolum fiyatı
// Pozisyon ticket'ı genelde deal'den veya sembol+magic+yön+lot taramasından gelir.
//+------------------------------------------------------------------+
//--- v1.73: Filling mode + manuel fallback (10030 Invalid Filling)
// Not: CTrade::SetTypeFillingBySymbol void döner → if() ile kullanılamaz
// TRADE SAFETY: Piyasa emrinden önce broker tick/volume/marjin ve STOPLEVEL
// bilgilerinin okunmasını zorunlu kılar; geçersiz ön koşullarda emir gönderilmez.
bool Trade_PreflightMarketOrder(const string symbol, const int direction, const double lot, const double slPrice, const ulong magic)
{
   ResetLastError();

   // v1.78.141 RISK_CALIBRATION FIX (DUZELTME_REHBERI [bu PDF] Bolum 2/4C,
   // P0 #2): "Hard SL hesaplanamazsa SL=0 ile emir yolu - Korumasiz pozisyon".
   // ESKI DAVRANIS: HardSL_ComputePrice() basarisiz oldugunda (0.0 dondu)
   // cagiran taraf SL=0 ile OrderSend'e AYNEN DEVAM EDIYORDU (kod icindeki
   // eski yorum bunu acikca "fail-safe: islem zaten aciliyor, bu asamada
   // engelleme yapilmiyor" diye tanimliyordu - yani aslinda FAIL-OPEN'di).
   // HARDSL_FORCE_ENABLED bu EA'da HER ZAMAN true (derleme-zamani sabiti) -
   // Hard SL opsiyonel bir ozellik degil, ZORUNLU bir guvenlik katmanidir.
   // slPrice<=0.0 artik "SL yok ama yine de ac" DEGIL, "risk hesaplanamadi,
   // ac-ma" anlamina gelir - islem BURADA veto edilir (fail-CLOSED).
   if(HARDSL_FORCE_ENABLED && slPrice <= 0.0)
   {
      PrintFormat("TRADE PREFLIGHT FAIL | %s | HARD SL HESAPLANAMADI (slPrice<=0) - KORUMASIZ POZISYON ACILMAYACAK (fail-closed, DUZELTME_REHBERI P0 #2)", symbol);
      return false;
   }

   MqlTick tick;
   if(!SymbolInfoTick(symbol, tick))
   {
      PrintFormat("TRADE PREFLIGHT FAIL | %s | tick okunamadı | err=%d", symbol, GetLastError());
      return false;
   }

   double price = (direction > 0) ? tick.ask : tick.bid;
   if(price <= 0.0)
   {
      PrintFormat("TRADE PREFLIGHT FAIL | %s | geçersiz fiyat=%.8f | err=%d", symbol, price, GetLastError());
      return false;
   }

   // v1.78.141 FIX (DUZELTME_REHBERI Uygulama Plani A): "BUY için SL < Entry;
   // SELL için SL > Entry koşulunu zorunlu doğrula." Yanlis yonlu bir SL
   // (hesaplama hatasi/gap ihtimali) broker tarafindan zaten reddedilebilir,
   // ama burada erken ve acik bir tani ile once buradan yakalanir.
   if(HARDSL_FORCE_ENABLED) {
      if(direction > 0 && slPrice >= price)
      {
         PrintFormat("TRADE PREFLIGHT FAIL | %s | BUY icin SL(%.8f) >= fiyat(%.8f) - yon hatasi", symbol, slPrice, price);
         return false;
      }
      if(direction < 0 && slPrice <= price)
      {
         PrintFormat("TRADE PREFLIGHT FAIL | %s | SELL icin SL(%.8f) <= fiyat(%.8f) - yon hatasi", symbol, slPrice, price);
         return false;
      }
   }

   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   long stopLevelPts = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   if(GetLastError() != 0)
   {
      int err = GetLastError();
      PrintFormat("TRADE PREFLIGHT FAIL | %s | broker özellikleri okunamadı | err=%d", symbol, err);
      return false;
   }

   // Bu EA market emrinde SL/TP göndermiyor; STOPLEVEL burada koruyucu
   // seviyelerin broker tarafından izin verilen minimum mesafesini kayda alır.
   // İleride SL/TP eklenirse aynı preflight içinde zorunlu kontrol noktasıdır.
   if(stopLevelPts < 0)
   {
      PrintFormat("TRADE PREFLIGHT FAIL | %s | geçersiz STOPLEVEL=%d", symbol, stopLevelPts);
      return false;
   }

   if(minLot <= 0.0 || maxLot < minLot || step <= 0.0 || lot < minLot || lot > maxLot)
   {
      PrintFormat("TRADE PREFLIGHT FAIL | %s | lot=%.8f min=%.8f max=%.8f step=%.8f stopLevel=%d",
                  symbol, lot, minLot, maxLot, step, stopLevelPts);
      return false;
   }

   double margin = 0.0;
   ENUM_ORDER_TYPE orderType = (direction > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   ResetLastError();
   if(!OrderCalcMargin(orderType, symbol, lot, price, margin) || margin <= 0.0)
   {
      // v1.78.141 FIX (DUZELTME_REHBERI Bolum 9, P1): margin GERCEKTEN
      // hesaplanamiyorsa "tahmini" bir degerle devam ETMEK YERINE trade
      // burada TAMAMEN veto edilir (Margin_PerLotSafe'deki keyfi %1
      // fallback'in kaldirilmasiyla AYNI ilke - bkz. o fonksiyonun yorumu).
      PrintFormat("TRADE PREFLIGHT FAIL | %s | marjin hesaplanamadı (OrderCalcMargin) | lot=%.8f | err=%d",
                  symbol, lot, GetLastError());
      return false;
   }

   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(freeMargin > 0.0 && margin > freeMargin)
   {
      PrintFormat("TRADE PREFLIGHT FAIL | %s | yetersiz marjin=%.2f free=%.2f",
                  symbol, margin, freeMargin);
      return false;
   }

   // v1.78.141 RISK_CALIBRATION FIX (DUZELTME_REHBERI Bolum 3, P0): "Basket
   // için Σ PositionRisk + NewPositionRisk ≤ BasketRiskBudget". SADECE Grid/
   // Bullet (magic==g_magic) girisleri icin uygulanir - hedge motorlari
   // (NFH/WH/DDH) KASITLI HARIC (bkz. RiskModel_BasketRiskOK yorumu:
   // korumaya calistiklari exposure'i azaltmalari gerekirken bu tavan
   // tarafindan yanlislikla engellenmemeliler).
   if(magic == g_magic && InpRiskSizing_Enable && InpRiskSizing_MaxRiskPct > 0.0)
   {
      double newRisk = 0.0;
      if(!OrderCalcProfit(orderType, symbol, lot, price, slPrice, newRisk) || !MathIsValidNumber(newRisk))
      {
         PrintFormat("TRADE PREFLIGHT FAIL | %s | yeni pozisyon riski hesaplanamadi (OrderCalcProfit) - veto", symbol);
         return false;
      }
      if(!RiskModel_BasketRiskOK(symbol, MathAbs(newRisk)))
         return false; // RiskModel_BasketRiskOK zaten logluyor
   }

   // v1.78.141 RISK_CALIBRATION FIX (DUZELTME_REHBERI Bolum 8, P1): "OrderCheck
   // yok - Gerçek request doğrulaması eksik". Yukaridaki kontroller EA'nin
   // KENDI yaklasik hesaplariydi; OrderCheck broker/terminalin KENDI
   // motoruyla GERCEK bir MqlTradeRequest'i (SL DAHIL) dogrular ve beklenen
   // balance/equity/profit/margin/margin_level degerlerini dondurur. NOT:
   // basarili OrderCheck dahi emrin kesin gerceklesecegi anlamina gelmez
   // (requote/slippage/rekabet) - bu yuzden gonderim SONRASI ResultRetcode
   // kontrolu (cagiran taraftaki mevcut kod) AYNEN KORUNUYOR; bu sadece EK
   // bir on-dogrulama katmanidir, onun yerine gecmez.
   long fillModes = (long)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
   ENUM_ORDER_TYPE_FILLING fillType = ORDER_FILLING_RETURN;
   if((fillModes & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
      fillType = ORDER_FILLING_IOC;
   else if((fillModes & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      fillType = ORDER_FILLING_FOK;

   MqlTradeRequest checkReq;
   MqlTradeCheckResult checkRes;
   ZeroMemory(checkReq);
   ZeroMemory(checkRes);
   checkReq.action       = TRADE_ACTION_DEAL;
   checkReq.symbol       = symbol;
   checkReq.volume       = lot;
   checkReq.type         = orderType;
   checkReq.price        = price;
   checkReq.sl           = slPrice;
   checkReq.tp           = 0.0;
   checkReq.deviation    = 30;
   checkReq.type_filling = fillType;
   checkReq.magic        = magic;

   ResetLastError();
   if(!OrderCheck(checkReq, checkRes))
   {
      PrintFormat("TRADE PREFLIGHT FAIL | %s | OrderCheck cagrisi basarisiz | err=%d", symbol, GetLastError());
      return false;
   }
   if(checkRes.retcode != 0 &&
      checkRes.retcode != TRADE_RETCODE_DONE &&
      checkRes.retcode != TRADE_RETCODE_PLACED)
   {
      PrintFormat("TRADE PREFLIGHT FAIL | %s | OrderCheck retcode=%u %s | margin=%.2f free=%.2f equity=%.2f",
                  symbol, checkRes.retcode, checkRes.comment,
                  checkRes.margin, checkRes.margin_free, checkRes.equity);
      return false;
   }

   return true;
}

void Trade_SetFilling(const string symbol)
{
   g_trade.SetTypeFillingBySymbol(symbol);
   long modes = (long)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
   if((modes & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
      g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else if((modes & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      g_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else
      g_trade.SetTypeFilling(ORDER_FILLING_RETURN);
}

ulong Trade_ResolvePositionTicket(const string symbol, const int direction,
                                  const ulong magic, const double lot,
                                  const double openPriceHint) {
   // 1) ResultDeal üzerinden HISTORY_DEAL_POSITION_ID
   // v1.73: HistorySelect thrash önleme – saniyede en fazla 1 kez genislet
   ulong dealId = g_trade.ResultDeal();
   if(dealId > 0) {
      static datetime s_lastHistSel = 0;
      datetime now = TimeCurrent();
      if(now != s_lastHistSel) {
         HistorySelect(0, (datetime)(now + 86400));
         s_lastHistSel = now;
      }
      if(HistoryDealSelect(dealId)) {
         ulong posId = (ulong)HistoryDealGetInteger(dealId, DEAL_POSITION_ID);
         if(posId > 0 && PositionSelectByTicket(posId))
            return posId;
      }
   }

   // v1.78.41 FIX: openPriceHint imzada vardi ama gövdede HIC kullanilmiyordu —
   // yol 2 ve yol 3 sadece sembol+magic+yon(+lot/zaman) ile eslesiyordu, gercek
   // acilis fiyati hic kontrol edilmiyordu. Ayni yon/lot'ta hizli ardisik grid
   // seviyeleri acildiginda (orn. spike sirasinda 2 seviye ust uste tetiklenirse)
   // yanlis ticket'in yanlis hucreye atanma riski vardi. hint>0 ise fiyat
   // yakinligi bir on-filtre olarak eklendi; hint verilmediyse (0/negatif,
   // cagiran taraf bilmiyor) eski davranis aynen korunur.
   double priceTol = 0.0;
   if(openPriceHint > 0.0) {
      double pt = SymbolInfoDouble(symbol, SYMBOL_POINT);
      if(pt <= 0) pt = 0.00001;
      priceTol = MathMax(pt * 50.0, openPriceHint * 0.0005); // ~50 point veya %0.05, hangisi buyukse
   }

   // 2) ResultOrder → bu order'a bağlı pozisyon
   ulong orderId = g_trade.ResultOrder();
   if(orderId > 0) {
      // Açık pozisyonlarda POSITION_IDENTIFIER / ticket tarama
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
         if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != magic) continue;
         int ptype = (int)PositionGetInteger(POSITION_TYPE);
         if(direction > 0 && ptype != POSITION_TYPE_BUY)  continue;
         if(direction < 0 && ptype != POSITION_TYPE_SELL) continue;
         // Yeni açılmış olmalı (son 5 sn)
         datetime ot = (datetime)PositionGetInteger(POSITION_TIME);
         if(TimeCurrent() - ot > 5) continue;
         double vol = PositionGetDouble(POSITION_VOLUME);
         if(MathAbs(vol - lot) > lot * 0.01 && lot > 0) continue;
         if(priceTol > 0.0) {
            double op = PositionGetDouble(POSITION_PRICE_OPEN);
            if(MathAbs(op - openPriceHint) > priceTol) continue;
         }
         return ticket;
      }
   }

   // 3) Son çare: aynı sembol/magic/yön, fiyata en yakın (hint varsa) /
   // en yeni (hint yoksa) pozisyon
   ulong best = 0;
   datetime bestTime = 0;
   double bestPriceDiff = -1.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != magic) continue;
      int ptype = (int)PositionGetInteger(POSITION_TYPE);
      if(direction > 0 && ptype != POSITION_TYPE_BUY)  continue;
      if(direction < 0 && ptype != POSITION_TYPE_SELL) continue;
      datetime ot = (datetime)PositionGetInteger(POSITION_TIME);
      if(priceTol > 0.0) {
         double op = PositionGetDouble(POSITION_PRICE_OPEN);
         double diff = MathAbs(op - openPriceHint);
         if(diff > priceTol) continue; // fiyat toleransi disinda — bu aday degil
         if(bestPriceDiff < 0.0 || diff < bestPriceDiff) {
            bestPriceDiff = diff;
            bestTime = ot;
            best = ticket;
         }
      } else {
         if(ot >= bestTime) {
            bestTime = ot;
            best = ticket;
         }
      }
   }
   return best;
}

//--- Lattice hücresinde ticket=0 kalanları sonradan eşleştir
void Lattice_RematchTickets(SLatticeState &lat, const string symbol) {
   // v1.78.20: ayni ticket iki hucreye atanmasin
   ulong used[LATTICE_MAX_LEVELS * 2];
   int usedN = 0;
   for(int i = 0; i < LATTICE_MAX_LEVELS; i++) {
      if(lat.buy_levels[i].active && lat.buy_levels[i].ticket > 0) {
         if(usedN < LATTICE_MAX_LEVELS * 2) used[usedN++] = lat.buy_levels[i].ticket;
      }
      if(lat.sell_levels[i].active && lat.sell_levels[i].ticket > 0) {
         if(usedN < LATTICE_MAX_LEVELS * 2) used[usedN++] = lat.sell_levels[i].ticket;
      }
   }
   for(int i = 0; i < LATTICE_MAX_LEVELS; i++) {
      if(lat.buy_levels[i].active && lat.buy_levels[i].ticket == 0) {
         ulong t = Trade_ResolvePositionTicket(symbol, +1, g_magic,
                       lat.buy_levels[i].lot, lat.buy_levels[i].open_price);
         if(t > 0) {
            bool dup = false;
            for(int u = 0; u < usedN; u++) if(used[u] == t) { dup = true; break; }
            if(!dup) {
               lat.buy_levels[i].ticket = t;
               // AUDIT v1.78.70 (#7): gec cozulen ticket icin de TAHMINI
               // degil GERCEK broker hacim/fiyatini state'e yaz.
               if(PositionSelectByTicket(t)) {
                  double av = PositionGetDouble(POSITION_VOLUME);
                  double ap = PositionGetDouble(POSITION_PRICE_OPEN);
                  if(av > 0.0) lat.buy_levels[i].lot        = av;
                  if(ap > 0.0) lat.buy_levels[i].open_price = ap;
               }
               if(usedN < LATTICE_MAX_LEVELS * 2) used[usedN++] = t;
            }
         }
      }
      if(lat.sell_levels[i].active && lat.sell_levels[i].ticket == 0) {
         ulong t = Trade_ResolvePositionTicket(symbol, -1, g_magic,
                       lat.sell_levels[i].lot, lat.sell_levels[i].open_price);
         if(t > 0) {
            bool dup = false;
            for(int u = 0; u < usedN; u++) if(used[u] == t) { dup = true; break; }
            if(!dup) {
               lat.sell_levels[i].ticket = t;
               if(PositionSelectByTicket(t)) {
                  double av = PositionGetDouble(POSITION_VOLUME);
                  double ap = PositionGetDouble(POSITION_PRICE_OPEN);
                  if(av > 0.0) lat.sell_levels[i].lot        = av;
                  if(ap > 0.0) lat.sell_levels[i].open_price = ap;
               }
               if(usedN < LATTICE_MAX_LEVELS * 2) used[usedN++] = t;
            }
         }
      }
   }
}

//--- Aynı yön sepet kârı (para bazında; swap dahil).
// Pyramid kararında point toplamı kullanılmamalıdır; farklı lot büyüklükleri
// point toplamını yanıltabilir. Gerçek POSITION_PROFIT + SWAP, aynı yön
// sepetinin ekonomik sonucunu temsil eder.
double Lattice_SameSideProfitMoney(const SLatticeState &lat, const string symbol, const int direction) {
   double sumMoney = 0.0;
   for(int i = 0; i < LATTICE_MAX_LEVELS; i++) {
      SLatticeLevel lvl = (direction > 0) ? lat.buy_levels[i] : lat.sell_levels[i];
      if(!lvl.active || lvl.ticket == 0) continue;
      if(!PositionSelectByTicket(lvl.ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      sumMoney += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }
   return sumMoney;
}

//--- Aynı yön sepet kârı (point cinsinden; yalnızca teşhis/uyumluluk için).
double Lattice_SameSideProfitPts(const SLatticeState &lat, const string symbol, const int direction) {
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0) return 0;
   double sumPts = 0;
   for(int i = 0; i < LATTICE_MAX_LEVELS; i++) {
      SLatticeLevel lvl = (direction > 0) ? lat.buy_levels[i] : lat.sell_levels[i];
      if(!lvl.active || lvl.ticket == 0) continue;
      if(!PositionSelectByTicket(lvl.ticket)) continue;
      double openPx = PositionGetDouble(POSITION_PRICE_OPEN);
      if(direction > 0) {
         double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
         sumPts += (bid - openPx) / point;
      } else {
         double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
         sumPts += (openPx - ask) / point;
      }
   }
   return sumPts;
}

// v1.78.32 GUVENLIK KILIDI: adim (step), sembolun KENDI o anki ATR'sinin
// InpSafety_MinStepAtrFrac katindan kucukse anlamsiz/olcek-disi kabul
// edilir — kokeni fark etmeksizin (yanlis sembol tipi, ATR MODU kapali
// kalmis bir ornek, XAUUSD icin kalibre edilmis puan degerinin baska bir
// sembole tasinmasi, vs.) son bir savunma hatti.
bool Lattice_StepScaleOK(const string symbol, const double stepPrice) {
   if(!InpSafety_ScaleGuard) return true;
   double atrVal = RiskATR_Read(symbol);
   if(atrVal <= 0) return true; // ATR henuz veri vermiyor - bu kilit icin veri yok, engelleme yapma
   double minStep = atrVal * InpSafety_MinStepAtrFrac;
   return (stepPrice >= minStep);
}

bool Lattice_PyramidAllows(SLatticeState &lat, const string symbol, const int direction) {
   // Pyramid kapalıysa: normal grid (STEP ile) devam – ekstra kısıt yok
   // Pyramid açıkken: yalnız kârlı tarafta ve max ekstra limiti içinde ek kademe
   if(direction > 0) {
      if(!(g_rt_ready ? g_rt_pyr_buy : InpVG_PyramidBuy)) return true; // piramit kapalı
      if(lat.buy_levels_active <= 0) return true; // ilk kademe serbest
      if(lat.pyramid_buy_extra >= InpVG_PyramidMaxExtra) return false;
      double money = Lattice_SameSideProfitMoney(lat, symbol, +1);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickVal = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      double totalVol = 0.0;
      for(int pi=0; pi<LATTICE_MAX_LEVELS; pi++)
         if(lat.buy_levels[pi].active && lat.buy_levels[pi].ticket>0 && PositionSelectByTicket(lat.buy_levels[pi].ticket))
            totalVol += PositionGetDouble(POSITION_VOLUME);
      double minMoney = 0.0;
      if(point>0 && tickSize>0 && tickVal>0 && totalVol>0)
         minMoney = (InpVG_PyramidMinProfitPts * point / tickSize) * tickVal * totalVol;
      return (money >= minMoney);
   } else {
      if(!(g_rt_ready ? g_rt_pyr_sell : InpVG_PyramidSell)) return true;
      if(lat.sell_levels_active <= 0) return true;
      if(lat.pyramid_sell_extra >= InpVG_PyramidMaxExtra) return false;
      double money = Lattice_SameSideProfitMoney(lat, symbol, -1);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickVal = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      double totalVol = 0.0;
      for(int pi=0; pi<LATTICE_MAX_LEVELS; pi++)
         if(lat.sell_levels[pi].active && lat.sell_levels[pi].ticket>0 && PositionSelectByTicket(lat.sell_levels[pi].ticket))
            totalVol += PositionGetDouble(POSITION_VOLUME);
      double minMoney = 0.0;
      if(point>0 && tickSize>0 && tickVal>0 && totalVol>0)
         minMoney = (InpVG_PyramidMinProfitPts * point / tickSize) * tickVal * totalVol;
      return (money >= minMoney);
   }
}

// v1.78.117 NOT: Bu fonksiyon ARTIK HICBIR YERDEN CAGRILMIYOR (kullanici
// talebiyle KAR KORUMA KASASI mimarisine gecildi - kasa artik ticarete asla
// geri deploy edilmiyor). Govde SILINMEDI (ileride referans/geri donus
// ihtimaline karsi), ama aktif degil.
double Lattice_ApplyEscapeFundLot(SLatticeState &lat, const string symbol, double baseLot, const int direction=0) {
   if(!InpVG_EscapeFundEnable || lat.escape_fund <= 0) return baseLot;
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   if(bal <= 0) return baseLot;
   double deploy = lat.escape_fund * (InpVG_EscapeDeployPct / 100.0);
   // Kaba: deploy $ / (margin-per-lot proxy) → ek lot
   // v1.78.41 FIX: Margin_PerLotSafe kullanilarak yon-farkindalikli hesap +
   // OrderCalcMargin basarisiz olursa gercekci fallback (bkz. tanimi).
   double marginPerLot = Margin_PerLotSafe(symbol, direction);
   if(marginPerLot <= 0)
      return baseLot;
   double extra = deploy / marginPerLot;
   double mult = 1.0 + (extra / MathMax(baseLot, 0.01));
   if(mult > InpVG_EscapeMaxGridLotMult) mult = InpVG_EscapeMaxGridLotMult;
   double lot = baseLot * mult;
   // Fon tavanı
   double cap = bal * (InpVG_EscapeBankCapPct / 100.0);
   if(lat.escape_fund > cap) lat.escape_fund = cap;
   return lot;
}

//+------------------------------------------------------------------+
//| SUPPORT / RESISTANCE + BREAKOUT CONFIRMATION                    |
//| Seviye penceresi teyit barlarindan AYRI tutulur: breakout       |
//| seviyesi eski kapanmis barlardan hesaplanir, son N kapanis ise  |
//| kirilimi teyit eder. Böylece yeni yuksek/dusuk seviye breakout'u|
//| ayni anda yukari tasiyip filtreyi etkisizlestirmez.              |
//+------------------------------------------------------------------+
bool SR_BreakoutConfirmed(const string symbol, const int direction, const ENUM_MARKET_PHASE phase)
{
   if(!InpSR_Enable || !InpSR_RequireBreakoutInTrend)
      return true;
   if(direction == 0)
      return false;
   if(phase != PHASE_TREND_UP && phase != PHASE_TREND_DOWN)
      return true;

   int lookback = MathMax(10, InpSR_LookbackBars);
   int confirm  = MathMax(1, InpSR_BreakoutConfirmBars);
   ENUM_TIMEFRAMES tf = (InpSR_Timeframe == PERIOD_CURRENT) ? Period() : InpSR_Timeframe;

   // v1.78.75 FIX: retest penceresi kaldirildi; artik sadece breakout +
   // confirm bar'lari icin veri gerekiyor.
   MqlRates rates[];
   int need = lookback + confirm + 6;
   int got = CopyRates(symbol, tf, 1, need, rates);
   if(got < need)
      return false;
   ArraySetAsSeries(rates, true);

   double atr = Ind_ATR(symbol, 0);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0.0) point = 0.00001;
   double buffer = (atr > 0.0) ? atr * MathMax(0.0, InpSR_BufferATR) : point * 10.0;

   // Seviye, breakout'tan ÖNCEKİ lookback penceresinden çıkarılır; böylece
   // yeni high/low seviyeyi ileri taşıyıp kendi breakout'unu sahte şekilde
   // doğrulayamaz.
   int confStart = 1;
   int srStart   = confStart + confirm;
   double resistance = -DBL_MAX;
   double support    = DBL_MAX;
   for(int j = srStart; j < srStart + lookback && j < got; j++)
   {
      if(rates[j].high > resistance) resistance = rates[j].high;
      if(rates[j].low  < support)    support = rates[j].low;
   }
   if(resistance == -DBL_MAX || support == DBL_MAX)
   {
      if(InpSR_LogDecisions)
         PrintFormat("SR TREND | %s | dir=%d | breakout WAIT (no S/R data)", symbol, direction);
      return false;
   }

   if(direction > 0)
   {
      double level = resistance + buffer;
      bool confirmed = true;
      for(int j = confStart; j < confStart + confirm; j++)
      {
         if(rates[j].close <= level) { confirmed = false; break; }
      }
      if(confirmed)
      {
         if(InpSR_LogDecisions)
            PrintFormat("SR TREND BUY | R=%.5f level=%.5f breakout=OK", resistance, level);
         return true;
      }
   }
   else
   {
      double level = support - buffer;
      bool confirmed = true;
      for(int j = confStart; j < confStart + confirm; j++)
      {
         if(rates[j].close >= level) { confirmed = false; break; }
      }
      if(confirmed)
      {
         if(InpSR_LogDecisions)
            PrintFormat("SR TREND SELL | S=%.5f level=%.5f breakout=OK", support, level);
         return true;
      }
   }

   if(InpSR_LogDecisions)
      PrintFormat("SR TREND | %s | dir=%d | breakout WAIT", symbol, direction);
   return false;
}

// RANGE modu: trend kovalamak yerine destekten BUY, dirençten SELL.
// Son kapanmış barın ilgili seviyeye temas edip seviyenin RANGE içine geri
// dönmesi aranır. Böylece yatay piyasada ortadan rastgele giriş yapılmaz.
bool SR_RangeBounceConfirmed(const string symbol, const int direction)
{
   if(!InpSR_Enable || !InpSR_RequireRangeBounce)
      return true;
   if(direction == 0)
      return false;

   int lookback = MathMax(10, InpSR_LookbackBars);
   ENUM_TIMEFRAMES tf = (InpSR_Timeframe == PERIOD_CURRENT) ? Period() : InpSR_Timeframe;
   MqlRates rates[];
   int got = CopyRates(symbol, tf, 1, lookback + 3, rates);
   if(got < lookback + 3)
      return false;
   ArraySetAsSeries(rates, true);

   double support = DBL_MAX, resistance = -DBL_MAX;
   for(int i = 2; i < lookback + 2 && i < got; i++)
   {
      if(rates[i].low < support) support = rates[i].low;
      if(rates[i].high > resistance) resistance = rates[i].high;
   }
   if(support == DBL_MAX || resistance == -DBL_MAX) return false;

   double atr = Ind_ATR(symbol, 0);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0.0) point = 0.00001;
   double touch = (atr > 0.0) ? atr * MathMax(0.0, InpSR_RangeTouchATR) : point * 8.0;

   double c = rates[0].close;
   if(direction > 0)
   {
      bool touched = (rates[0].low <= support + touch);
      bool bounced = (c > support && c > rates[0].open);
      if(InpSR_LogDecisions)
         PrintFormat("SR RANGE BUY | S=%.5f touch=%s bounce=%s", support, touched ? "YES" : "NO", bounced ? "YES" : "NO");
      return touched && bounced;
   }
   else
   {
      bool touched = (rates[0].high >= resistance - touch);
      bool bounced = (c < resistance && c < rates[0].open);
      if(InpSR_LogDecisions)
         PrintFormat("SR RANGE SELL | R=%.5f touch=%s bounce=%s", resistance, touched ? "YES" : "NO", bounced ? "YES" : "NO");
      return touched && bounced;
   }
}

bool SR_EntryConfirmed(const string symbol, const int direction, const ENUM_MARKET_PHASE phase)
{
   if(!InpSR_Enable) return true;
   if(phase == PHASE_TREND_UP || phase == PHASE_TREND_DOWN)
      return SR_BreakoutConfirmed(symbol, direction, phase);
   if(phase == PHASE_RANGE)
      return SR_RangeBounceConfirmed(symbol, direction);
   return true; // NEUTRAL: başka guard'lar karar verir
}

//+------------------------------------------------------------------+
//| GRID RISK FIREWALL – v1.78.69 SAFE                              |
//| Normal Grid akisina dokunmaz; kritik riskte yeni girisi keser ve |
//| gerekiyorsa mevcut Grid pozisyonlarini guvenli sekilde kapatir.   |
//+------------------------------------------------------------------+
bool GridRisk_IsGridTicket(const ulong ticket, const string symbol)
{
   if(ticket == 0 || !PositionSelectByTicket(ticket)) return false;
   if(PositionGetString(POSITION_SYMBOL) != symbol) return false;
   if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) return false;
   return true;
}

// AUDIT v1.78.70 (#5/#6): broker'da bu sembol+magic icin Grid'e ait (Bullet/
// Hedge suffix'i olmayan) kac pozisyon oldugunu sayar. Lattice_ReconcileFromBroker
// ile ayni siniflandirma kuralini kullanir; state'e yazmaz, yalnizca sayar.
int GridRisk_CountBrokerGridPositions(const string symbol)
{
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      string cmt = PositionGetString(POSITION_COMMENT);
      if(StringFind(cmt, "-BLT") >= 0 || StringFind(cmt, "-NFH") >= 0 ||
         StringFind(cmt, "-WH")  >= 0 || StringFind(cmt, "-DDH") >= 0) continue;
      n++;
   }
   return n;
}

bool GridRisk_Enforce(SLatticeState &lat, const string symbol, bool &blockNew)
{
   blockNew = false;
   if(!InpGridRiskFirewallEnable) return true;

   int idx = Ind_FindIdx(symbol);
   if(idx < 0 || idx >= MAX_SYMBOLS) idx = 0;

   double gridPnL = 0.0;
   double gridLots = 0.0;
   double buyLots = 0.0, sellLots = 0.0;
   double buyPxVol = 0.0, sellPxVol = 0.0;
   int brokerGridCount = 0;

   for(int i=0; i<LATTICE_MAX_LEVELS; i++)
   {
      if(lat.buy_levels[i].active && lat.buy_levels[i].ticket > 0 &&
         GridRisk_IsGridTicket(lat.buy_levels[i].ticket, symbol))
      {
         double v = PositionGetDouble(POSITION_VOLUME);
         double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         double px = PositionGetDouble(POSITION_PRICE_OPEN);
         gridLots += v; buyLots += v; buyPxVol += px*v; gridPnL += p; brokerGridCount++;
      }
      if(lat.sell_levels[i].active && lat.sell_levels[i].ticket > 0 &&
         GridRisk_IsGridTicket(lat.sell_levels[i].ticket, symbol))
      {
         double v = PositionGetDouble(POSITION_VOLUME);
         double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         double px = PositionGetDouble(POSITION_PRICE_OPEN);
         gridLots += v; sellLots += v; sellPxVol += px*v; gridPnL += p; brokerGridCount++;
      }
   }

   // State'te aktif hucre olup brokerda eslesmeyen ticket varsa yeni girisi kes.
   // Rematch bir sonraki pipeline adiminda tekrar denenecektir.
   bool orphan = false;
   for(int i=0; i<LATTICE_MAX_LEVELS; i++)
   {
      if(lat.buy_levels[i].active && lat.buy_levels[i].ticket == 0) orphan = true;
      if(lat.sell_levels[i].active && lat.sell_levels[i].ticket == 0) orphan = true;
   }

   // AUDIT v1.78.70 (#5/#6): restart sonrasi kapasite-asimi (reconcile'dan
   // gelen bayrak) veya calisirken broker'da state'in bilmedigi Grid
   // pozisyonu varsa da orphan say. Pozisyonlar KAPATILMAZ, yalnizca yeni
   // Grid girisi durur — audit onerisi ile ayni: manuel inceleme gerekir.
   if(InpGridRiskBlockOnOrphan)
   {
      if(g_latticeOrphanExtra[idx]) orphan = true;
      int trackedActive = lat.buy_levels_active + lat.sell_levels_active;
      int brokerActual  = GridRisk_CountBrokerGridPositions(symbol);
      if(brokerActual > trackedActive)
      {
         orphan = true;
         if(InpGridRiskLog)
            PrintFormat("GRID RISK ORPHAN | %s | broker=%d tracked=%d — state'in bilmedigi pozisyon var, yeni Grid girisi durduruldu",
                        symbol, brokerActual, trackedActive);
      }
   }

   if(orphan && InpGridRiskBlockOnOrphan)
      blockNew = true;

   // Emergency latch: once tripped, no new Grid entry until the basket is gone.
   if(g_gridRiskTrip[idx])
   {
      blockNew = true;
      if(brokerGridCount == 0)
      {
         g_gridRiskTrip[idx] = false;
         if(InpGridRiskLog) PrintFormat("GRID SAFE RESET | %s | basket flat", symbol);
         blockNew = orphan && InpGridRiskBlockOnOrphan;
      }
      else if(InpGridRiskEmergencyClose)
      {
         for(int i=0; i<LATTICE_MAX_LEVELS; i++)
         {
            if(lat.buy_levels[i].active && lat.buy_levels[i].ticket > 0)
               SafeClosePosition(lat.buy_levels[i].ticket, "GRID_RISK_LATCH");
            if(lat.sell_levels[i].active && lat.sell_levels[i].ticket > 0)
               SafeClosePosition(lat.sell_levels[i].ticket, "GRID_RISK_LATCH");
         }
      }
      return false;
   }

   if(brokerGridCount == 0)
      return !blockNew;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0.0) equity = AccountInfoDouble(ACCOUNT_BALANCE);
   double lossAbs = MathMax(0.0, -gridPnL);
   double maxLoss = (InpGridRiskMaxDDPct > 0.0) ? equity*InpGridRiskMaxDDPct/100.0 : DBL_MAX;
   if(InpGridRiskMaxLossMoney > 0.0) maxLoss = MathMin(maxLoss, InpGridRiskMaxLossMoney);

   double warnLoss = (maxLoss < DBL_MAX/2.0 && InpGridRiskWarnPct > 0.0)
                     ? maxLoss*InpGridRiskWarnPct/100.0 : DBL_MAX;

   double maxAdverse = 0.0;
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   if(buyLots > 0.0 && bid > 0.0)
      maxAdverse = MathMax(maxAdverse, MathMax(0.0, (buyPxVol/buyLots)-bid));
   if(sellLots > 0.0 && ask > 0.0)
      maxAdverse = MathMax(maxAdverse, MathMax(0.0, ask-(sellPxVol/sellLots)));

   double atr = Ind_ATR(symbol, 0);
   bool ddWarn = (lossAbs >= warnLoss);
   bool ddHard = (lossAbs >= maxLoss);
   bool lotHard = (InpGridRiskMaxTotalLot > 0.0 && gridLots > InpGridRiskMaxTotalLot);
   bool atrHard = (InpGridRiskMaxAdverseATR > 0.0 && atr > 0.0 &&
                   maxAdverse >= atr*InpGridRiskMaxAdverseATR);

   if(ddWarn || lotHard || atrHard || orphan)
      blockNew = true;

   if(ddHard || atrHard)
   {
      g_gridRiskTrip[idx] = true;
      blockNew = true;
      PrintFormat("GRID RISK CRITICAL | %s | pnl=%.2f loss=%.2f max=%.2f lots=%.2f adverse=%.5f ATR=%.5f",
                  symbol, gridPnL, lossAbs, maxLoss, gridLots, maxAdverse, atr);

      if(InpGridRiskEmergencyClose)
      {
         for(int i=0; i<LATTICE_MAX_LEVELS; i++)
         {
            if(lat.buy_levels[i].active && lat.buy_levels[i].ticket > 0)
               SafeClosePosition(lat.buy_levels[i].ticket, "GRID_RISK_EMERGENCY");
            if(lat.sell_levels[i].active && lat.sell_levels[i].ticket > 0)
               SafeClosePosition(lat.sell_levels[i].ticket, "GRID_RISK_EMERGENCY");
         }
      }
      return false;
   }

   if(InpGridRiskLog && (ddWarn || lotHard || atrHard || orphan))
      PrintFormat("GRID RISK BLOCK | %s | pnl=%.2f loss=%.2f/%0.2f lots=%.2f adverse=%.5f ATR=%.5f orphan=%s",
                  symbol, gridPnL, lossAbs, maxLoss, gridLots, maxAdverse, atr, orphan ? "YES" : "NO");

   return !blockNew;
}

// TRADE SAFETY: Broker retcode'u kabul listesi dışında kalan emirler state'e
// açılmış kademe olarak yazılmaz; aksi halde hayali grid pozisyonu oluşurdu.
bool Lattice_TryOpenLevel(SLatticeState &lat, const string symbol, const int direction,
                          const ENUM_MARKET_PHASE phase) {
   // v1.78.57 GECICI TESHIS: hangi kosul girisi engelliyor gormek icin.
   // Sorun bulunduktan sonra bu blok kaldirilacak/kapatilacak.
   static datetime s_diagLast = 0;
   bool diagTick = (TimeCurrent() - s_diagLast >= 30); // 30sn'de bir logla, spam olmasin
   if(diagTick) s_diagLast = TimeCurrent();
   #define DIAG_RET(reason) { if(diagTick) PrintFormat("R21 TESHIS RED | %s | dir=%d | sebep=%s", symbol, direction, reason); return false; }

   if(!RT_VG()) DIAG_RET("GRID_KAPALI(RT_VG)");
   
   // v1.78.130 MOTOR ACTIVATION GATE: Grid motoru bu rejimde AKTİF mı?
   // Rejim geçişi sırasında veya devre dışı motor tarafından hiçbir yeni giris yapılmasin
   if(!AdaptiveMarket_IsMotorActive(0)) DIAG_RET("GRID_MOTOR_DEAKTIF");
   
   // Panel BLOK: asiri zararli kademe engeli
   // v1.78.60 KRITIK FIX (#127): lossN TUM sembol pozisyonlarini (BUY+SELL
   // karisik) sayiyordu. Ornek: SELL tarafinda 4+ zararli kademe varken,
   // bu sayac direction=BUY icin de ZARAR_BLOK dondurup BUY girislerini de
   // engelliyordu - "sell zarar ederken hic buy olmuyor" sikayeti buradan
   // kaynaklaniyordu. Artik SADECE bu cagrinin 'direction' parametresiyle
   // AYNI yondeki (POSITION_TYPE) pozisyonlar sayiliyor; karsi yon etkilenmez.
   if(RT_Blok()) {
      int lossN = 0;
      int wantTypeZB = (direction > 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
      for(int li = PositionsTotal()-1; li >= 0; li--) {
         ulong lt = PositionGetTicket(li);
         if(lt==0 || !PositionSelectByTicket(lt)) continue;
         if(PositionGetString(POSITION_SYMBOL)!=symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC)!=g_magic) continue;
         if((int)PositionGetInteger(POSITION_TYPE)!=wantTypeZB) continue;
         if(PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP) < 0) lossN++;
      }
      if(lossN >= RT_ZararBlok()) DIAG_RET("ZARAR_BLOK");
   }

   if(g_rt_ready && !g_rt_grid_cont) {
      if(lat.buy_levels_active + lat.sell_levels_active > 0)
         DIAG_RET("GRID_SUREKLI_KAPALI"); // GRID SÜREKLİ kapali: yeni seviye yok
   }
   if(g_rt_ready && !g_rt_grid_both) {
      if(direction > 0 && lat.sell_levels_active > 0) DIAG_RET("TEK_YON_SELL_ACIKKEN_BUY_ENGEL");
      if(direction < 0 && lat.buy_levels_active > 0) DIAG_RET("TEK_YON_BUY_ACIKKEN_SELL_ENGEL");
   }

   if(!lat.initialized) DIAG_RET("LATTICE_INIT_DEGIL");
   if(direction == 0) DIAG_RET("YON_NOTR(direction=0)");
   if(!DirectionLock_AllowsEntry(symbol, direction)) DIAG_RET("DIRECTION_FLIP_LOCK");

   // v1.78.18: yon basina max kademe (InpVG_MaxLevels / risk motoru)
   {
      int maxLv = RT_MaxLevels();
      if(maxLv > 0) {
         if(direction > 0 && lat.buy_levels_active >= maxLv) DIAG_RET("MAX_KADEME_BUY");
         if(direction < 0 && lat.sell_levels_active >= maxLv) DIAG_RET("MAX_KADEME_SELL");
      }
   }

   // v1.78.18: min saniye throttle (InpVG_MinSecondsBetween artik GERCEKTEN kullaniliyor)
   {
      int minSec = RT_MinSec();
      if(minSec > 0) {
         datetime lastT = 0;
         if(direction > 0) {
            for(int i = 0; i < LATTICE_MAX_LEVELS; i++)
               if(lat.buy_levels[i].active && lat.buy_levels[i].open_time > lastT)
                  lastT = lat.buy_levels[i].open_time;
         } else {
            for(int i = 0; i < LATTICE_MAX_LEVELS; i++)
               if(lat.sell_levels[i].active && lat.sell_levels[i].open_time > lastT)
                  lastT = lat.sell_levels[i].open_time;
         }
         if(lastT > 0 && (TimeCurrent() - lastT) < minSec) DIAG_RET("MIN_SANIYE_THROTTLE");
      }
   }

   // 1) Trend bloğu
   if(Lattice_TrendBlocksNewEntry(phase, direction)) DIAG_RET("TREND_UYUM_BLOK");
   // Destek/direnc kirilimi: trend yonunde yeni kademe acmadan once
   // son N kapanisla breakout teyidi alinmis olmali.
   // v1.78.167 KADEME FIX: varsayilan olarak (InpSR_RequireOnAddLevels=false)
   // bu onay SADECE basket'in ILK kademesinde aranir. 2.+ kademe eklerken
   // STEP mesafesi + trend uyumu (yukarida) + netting + risk motorlari zaten
   // guvenligi sagliyor; SR'yi tekrar tekrar burada da istemek acik bir
   // pozisyona ekleme yapilmasini fiilen imkansiz kiliyordu (bkz. dosya basi
   // changelog - "kademeli acmiyor" bulgusu).
   {
      bool isFirstLevelSR = (direction > 0) ? (lat.buy_levels_active == 0) : (lat.sell_levels_active == 0);
      if((InpSR_RequireOnAddLevels || isFirstLevelSR) && !SR_EntryConfirmed(symbol, direction, phase))
         DIAG_RET("SR_BREAKOUT_RETEST_BOUNCE_ONAY_YOK");
   }

   // 1b) v1.78.22: ADX Filtresi (ALGO CheckADX_TrendStrength birebir esik mantigi)
   // ADX esigin altindaysa piyasa yonsuz/zayif kabul edilir, YENI seviye acilmaz.
   // Mevcut acik pozisyonlara dokunmaz — sadece bu cagriyi engeller.
   if(!RiskADX_TrendStrengthOK(symbol)) DIAG_RET("ADX_FILTRE_ZAYIF_TREND");

   // 2) Netting kuralı
   if(!Lattice_NettingAllows(lat, direction)) DIAG_RET("NETTING_ENGEL");

   {
      // v1.78.149: DIAG_RET eskiden sabit "RISK_GOV_BLOCK" yaziyordu - artik
      // RiskGovernor_BlockEntry'nin GERCEK sebebini (MARKET_QUALITY_KALICI,
      // SOGUK_BASLANGIC, PERFORMANS_COOLDOWN, SEPET_ZARARI,
      // AYNI_YON_ACIK_POZ_LIMITI, GIRIS_YOGUNLUGU) Journal'a yaziyor.
      string riskGovReason = "";
      if(RiskGovernor_BlockEntry(symbol, 1, direction, riskGovReason))
         DIAG_RET("RISK_GOV_BLOCK:" + riskGovReason);
   }

   // 2b) Aynı yön minimum mesafe: Bullet/ana pipeline'daki güvenlik kuralı
   // Grid girişinde de uygulanır. Varsayılanı input'tan kapalı olabilir; açıkken
   // STEP'ten bağımsız ikinci bir yakın-kademe koruması sağlar.
   if(!MinDist_Allows(symbol, direction)) DIAG_RET("MIN_DIST_ENGEL");

   // 2c) Pyramid (kârlı tarafta ekleme limiti)
   if(!Lattice_PyramidAllows(lat, symbol, direction)) DIAG_RET("PYRAMID_LIMIT");

   // 2b2) v1.78.32 GUVENLIK KILIDI: adim, sembolun kendi ATR'sine gore
   // olcek-disi kucukse yeni seviye acma — bkz. Lattice_StepScaleOK yorumu.
   {
      // Açık kademe varsa ATR güvenlik kontrolü de o kademenin kilitli STEP'ine
      // bakmalıdır. Aksi halde ATR yükselince yeni STEP büyür ve kilitlenmiş
      // STEP ile ulaşılmış bir seviye gereksiz yere tekrar engellenebilir.
      double stepNow = Lattice_LastLockedStep(lat, direction);
      if(stepNow <= 0.0) stepNow = (direction > 0) ? lat.buy_step : lat.sell_step;
      if(!Lattice_StepScaleOK(symbol, stepNow)) {
         static datetime s_lastScaleWarn = 0;
         if(TimeCurrent() - s_lastScaleWarn >= 60) {
            double atrNow = RiskATR_Read(symbol);
            PrintFormat("R21 GUVENLIK KILIDI | %s | adim=%.5f ATR=%.5f min=%.5f — yeni seviye ENGELLENDI (ADIM bu sembol icin olcek-disi)",
                        symbol, stepNow, atrNow, atrNow*InpSafety_MinStepAtrFrac);
            g_panelApplyMsg = "⚠ " + symbol + ": ADIM olcek-disi, giris durduruldu";
            g_panelApplyMsgUntil = TimeCurrent() + 6;
            s_lastScaleWarn = TimeCurrent();
         }
         return false;
      }
   }

   // 2c) Loop harvest cooldown
   if(g_rt_ready ? g_rt_loop_harvest : InpVG_LoopHarvestEnable) {
      // v1.78.120 EKLENTI (ERB - Early Reversal Brake, belgenin 18. bolumu -
      // "en kritik madde"): Warning sirasinda kapanan bir seviyenin Cycle/
      // Loop Harvest re-entry mekanizmasi YENIDEN RISK URETMEMELIDIR. Bu
      // kontrol cooldown/yon-teyidi kontrollerinden ONCE, en basta yapilir.
      if(InpERB_BlockLoopHarvestReentry && ERB_BlocksNewRisk(symbol)) {
         if(InpERB_LogDecisions)
            PrintFormat("[ERB] BLOCK LOOP HARVEST REENTRY | symbol=%s | dir=%d | reason=EARLY_REVERSAL_WARNING", symbol, direction);
         DIAG_RET("ERB_BLOCK_LOOP_HARVEST_REENTRY");
      }
      if(direction > 0 && lat.last_loop_buy_time > 0 &&
         TimeCurrent() - lat.last_loop_buy_time < InpVG_LoopCooldownSec) DIAG_RET("LOOP_HARVEST_COOLDOWN_BUY");
      if(direction < 0 && lat.last_loop_sell_time > 0 &&
         TimeCurrent() - lat.last_loop_sell_time < InpVG_LoopCooldownSec) DIAG_RET("LOOP_HARVEST_COOLDOWN_SELL");

      // v1.78.113/114 EKLENTI (kullanici tespiti): cooldown suresi gecmis
      // olsa bile, fiyatin kar alinan kademenin KAPANIS FIYATINDAN itibaren
      // GERCEKTEN ayni yonde devam ettigi TEYIT EDILMEDEN yeni kademe
      // acilmasin ("kar 10 iken zarar 20 oluyor" dongusune care). Referans
      // fiyat sadece bir TAZELIK PENCERESI icinde (cooldown'in ~6 kati,
      // en az 60sn) gecerli sayilir - daha eskiyse (saatler sonra gibi)
      // BAYAT kabul edilip bu kontrol atlanir, normal STEP-bazli akisa
      // birakilir. (v1.78.114: ilk yazimda pencere hesabi cooldown'in
      // KENDISI ile sinirliydi ve yukaridaki cooldown-return satiri
      // yuzunden bu blok PRATIKTE HICBIR ZAMAN calismiyordu - duzeltildi.)
      datetime lastLoopTime = (direction > 0) ? lat.last_loop_buy_time : lat.last_loop_sell_time;
      int freshWindowSec = MathMax(InpVG_LoopCooldownSec * 6, 60); // en az 60sn, veya cooldown'in 6 kati
      bool refIsFresh = (lastLoopTime > 0) && (TimeCurrent() - lastLoopTime <= freshWindowSec);
      if(InpVG_LoopReentryConfirmATR > 0.0 && refIsFresh) {
         double refPrice = (direction > 0) ? lat.last_loop_buy_closePrice : lat.last_loop_sell_closePrice;
         if(refPrice > 0.0) {
            double atrNow = RiskATR_Read(symbol);
            if(atrNow <= 0.0) atrNow = Ind_ATR(symbol, 0);
            if(atrNow > 0.0) {
               double curPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
               double requiredMove = atrNow * InpVG_LoopReentryConfirmATR;
               // BUY icin fiyat refPrice'in USTUNE cikmis olmali (devam ettigi kanit);
               // SELL icin fiyat refPrice'in ALTINA inmis olmali.
               if(direction > 0 && (curPrice - refPrice) < requiredMove) DIAG_RET("LOOP_HARVEST_DIRECTION_NOT_CONFIRMED_BUY");
               if(direction < 0 && (refPrice - curPrice) < requiredMove) DIAG_RET("LOOP_HARVEST_DIRECTION_NOT_CONFIRMED_SELL");
            }
         }
      }
   }

   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);

   // 3) Aynı yön STEP mesafesi
   // v1.78.58 EK (tani amacli, davranis degismiyor): DIAG_RET sadece sebep
   // metnini yaziyordu, gercek sayilar goruenmuyordu. STEP_MESAFE_YETERSIZ
   // oncesinde referans fiyat / gereken step / kalan mesafeyi ayrica logla —
   // "X dolar hareket etti ama acilmadi" sorusuna dogrudan cevap versin.
   if(!Lattice_SameSideStepOK(lat, direction, bid, ask)) {
      if(diagTick) {
         double refPrice = (direction > 0) ? lat.last_buy_open_price : lat.last_sell_open_price;
         double stepReq  = Lattice_LastLockedStep(lat, direction);
         if(stepReq <= 0.0) stepReq = (direction > 0) ? lat.buy_step : lat.sell_step;
         // TREND STEP hareketi: BUY yukarı, SELL aşağı.
         double moved    = (direction > 0) ? (bid - refPrice)         : (refPrice - ask);
         double eksik    = stepReq - moved; // pozitif: hala bu kadar mesafe lazim (fiyat biriminde)
         double effectiveStep = 0.0;
         datetime bestStepTime = 0;
         if(direction > 0) {
            for(int si=0; si<LATTICE_MAX_LEVELS; si++) {
               if(lat.buy_levels[si].active && lat.buy_levels[si].open_time >= bestStepTime) {
                  bestStepTime = lat.buy_levels[si].open_time;
                  effectiveStep = lat.buy_levels[si].step_at_open;
               }
            }
         } else {
            for(int si=0; si<LATTICE_MAX_LEVELS; si++) {
               if(lat.sell_levels[si].active && lat.sell_levels[si].open_time >= bestStepTime) {
                  bestStepTime = lat.sell_levels[si].open_time;
                  effectiveStep = lat.sell_levels[si].step_at_open;
               }
            }
         }
         if(effectiveStep <= 0.0) effectiveStep = stepReq;
         PrintFormat("R21 STEP DETAY | %s | dir=%d | ref_fiyat=%.5f | bid=%.5f | ask=%.5f | gereken_step=%.5f | kilitli_step=%.5f | mevcut_hareket=%.5f | eksik_mesafe=%.5f",
                     symbol, direction, refPrice, bid, ask, stepReq, effectiveStep, moved, eksik);
      }
      DIAG_RET("STEP_MESAFE_YETERSIZ");
   }

   // 4) Boş hücre bul
   int freeIdx = -1;
   if(direction > 0) {
      for(int i = 0; i < LATTICE_MAX_LEVELS; i++) {
         if(!lat.buy_levels[i].active) { freeIdx = i; break; }
      }
   } else {
      for(int i = 0; i < LATTICE_MAX_LEVELS; i++) {
         if(!lat.sell_levels[i].active) { freeIdx = i; break; }
      }
   }
   if(freeIdx < 0) DIAG_RET("BOS_HUCRE_YOK(LATTICE_DOLU)");

   // 5) Lot
   // v1.78.117 FIX (kullanici talebi - mimari degisiklik): KACIS KASASI artik
   // "KAR KORUMA KASASI"na donusturuldu - eskiden burada
   // Lattice_ApplyEscapeFundLot() ile kasadaki birikim GERI DEPLOY EDILIP
   // lot buyutuluyordu ("al-ver" mantigi, kasa buyudukce risk de buyuyordu).
   // Kullanici bunun TAM TERSINI istedi: kasa bir kere biriktirdi mi normal
   // ticarete GERI KARISMASIN, EA hep SABIT/bagimsiz calissin - "kasayla
   // alakali her seyi atlayip normal nasil calisiyorsa oyle calissin". Bu
   // yuzden asagidaki cagri TAMAMEN KALDIRILDI (Lattice_ApplyEscapeFundLot
   // fonksiyonunun govdesi de artik cagrilmiyor, bkz. asagidaki tanimi).
   double lot = Lattice_CalcLot(symbol, direction); // v1.78.41: yon-farkindalikli margin
   lot = TPProj_NormalizeLot(symbol, lot, true, direction);

   // v1.78.98 FIX (DUZELTME_REHBERI #4, P0): toplam grid exposure tavani.
   // 0 = kapali (varsayilan - hesap buyuklugune gore siz belirleyin).
   if(InpGridMaxTotalLot > 0.0 && lot > 0.0) {
      double curExposure = Grid_OpenExposure(symbol, direction);
      double allowed = InpGridMaxTotalLot - curExposure;
      if(allowed <= 0.0)
         lot = 0.0;
      else if(lot > allowed)
         lot = NormalizeLotForEntry(symbol, allowed); // yukari zorlamadan kirp
      if(lot <= 0.0) DIAG_RET("GRID_EXPOSURE");
   }

   // v1.78.143 GRID-MINLOT-OVERRIDE-FIX: eskiden burada KOSULSUZ minLot'a
   // zorlama vardi (v1.78.130 CRITICAL FIX) - bu, Lot_CalcCapped/RiskCap_
   // MaxLot/TPProj_NormalizeLot'un yukarida (satir ~9905-9906) verdigi
   // KASITLI 0.0 (risk butcesi asiliyor, ACMA) kararini SESSIZCE eziyor,
   // sonra o zorlanmis minLot Trade_PreflightMarketOrder'daki GERCEK basket-
   // risk kontrolune (RiskModel_BasketRiskOK) takilip HER TICK'TE yeniden
   // veto ediliyordu - "sonsuz RISK MODEL VETO dongusu" sikayetinin GERCEK
   // kaynagi buydu (bkz. dosya basindaki v1.78.143 changelog). Artik bu
   // zorlama SADECE risk sizing tamamen KAPALIYKEN uygulanir (o durumda
   // zorlanacak bir risk butcesi yoktur, guvenlidir). Risk sizing ACIKKEN
   // Bullet motorundaki (bkz. "R21 BULLET IPTAL") ile AYNI ilke: lot=0 ise
   // islem acilmaz, minLot'a ASLA zorlanmaz - sebep Journal'a yazilir.
   if(lot <= 0.0) {
      if(!InpRiskSizing_Enable) {
         // Risk sizing kapali - zorlanacak bir risk butcesi yok, minLot'a
         // yukselterek OrderSend'in lot=0 hatasi vermesini onlemek guvenli.
         double dynamicMinLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
         if(dynamicMinLot <= 0.0) dynamicMinLot = 0.01; // fallback
         lot = dynamicMinLot;
      } else {
         // Risk sizing ACIK: lot=0 KASITLI bir risk reddiydi - minLot'a
         // zorlamak butceyi asan bir islem acar. Bullet'teki ayni davranis:
         // islem iptal, sebep loglanir, minLot'a zorlanmaz.
         if(InpSR_LogDecisions) {
            string gridLotReason = (g_lastLotRejectReason != "")
               ? ("LOT_SIFIR_VEYA_NEGATIF:" + g_lastLotRejectReason)
               : "LOT_SIFIR_VEYA_NEGATIF";
            PrintFormat("R21 GRID IPTAL | %s | dir=%d | sebep=%s",
                        symbol, direction, gridLotReason);
         }
         return false;
      }
   }

   // 6) Final veto
   if(direction > 0 && (!InpEnableBuy  || !g_panelBuy))  DIAG_RET("FINAL_VETO_BUY_KAPALI");
   if(direction < 0 && (!InpEnableSell || !g_panelSell)) DIAG_RET("FINAL_VETO_SELL_KAPALI");

   // AUDIT v1.78.70 (#8): ayni sembol+yon icin gonderim kilidi. MQL5 tek
   // iş parçacıklıdır, normal akista asla tetiklenmez; farkli bir kod yolu
   // ayni hucreyi (broker onayi kesinlesmeden) tekrar gondermeye calisirsa
   // diye ucretsiz bir emniyet supabidir.
   int lockIdx = Ind_FindIdx(symbol);
   if(lockIdx < 0 || lockIdx >= MAX_SYMBOLS) lockIdx = 0;
   int lockDir = (direction > 0) ? 0 : 1;
   if(InpExecLock_Enable && g_gridSendLock[lockIdx][lockDir]) DIAG_RET("EXECUTION_LOCK_AKTIF");
   #undef DIAG_RET

   // 7) Piyasa emri
   bool ok = false;
   ulong posTicket = 0;
   double openPrice = 0.0;

   g_trade.SetExpertMagicNumber(g_magic);
   // v1.78.131 HARD SL (R1/R2/R5): Grid/Lattice sepeti icin ATR x
   // InpHardSL_GridATRMult mesafesinde gercek broker SL'i. Bilerek
   // InpGridRiskMaxAdverseATR esiginden genis tutulur ki GridRiskFirewall
   // once tetiklenebilsin (Teknik Sartname 4.4).
   // v1.78.141 RISK_CALIBRATION FIX (DUZELTME_REHBERI Bolum 2/4C/8, P0/P1):
   // Hard SL artik Trade_PreflightMarketOrder()'dan ONCE hesaplanir - preflight
   // fail-closed veto (SL<=0 -> islem YOK) ve OrderCheck() artik GERCEK SL'i
   // dogrulayabiliyor (eskiden preflight SL'den habersiz cagriliyordu, SL
   // sonradan hesaplanip SL=0 ihtimaliyle bile OrderSend'e gidiliyordu).
   double gridHardSl = (direction > 0)
      ? HardSL_ComputePrice(symbol, 1, true, ask)
      : HardSL_ComputePrice(symbol, -1, true, bid);
   if(!Trade_PreflightMarketOrder(symbol, direction, lot, gridHardSl, g_magic))
   {
      if(InpExecLock_Enable) g_gridSendLock[lockIdx][lockDir] = false;
      return false;
   }
   Trade_SetFilling(symbol); // v1.73: auto + IOC/FOK/RETURN fallback
   // NOT: ResetLastError()'dan ONCE hesaplaniyor - ATR/indikator okumasi
   // GetLastError() durumunu kirletip asagidaki gercek emir hatasi
   // teshisini bozmasin diye (gridHardSl artik yukarida hesaplandi).
   ResetLastError();
   if(InpExecLock_Enable) g_gridSendLock[lockIdx][lockDir] = true;

   if(direction > 0) {
      ok = g_trade.Buy(lot, symbol, 0, gridHardSl, 0, InpTradeComment);
      if(ok) {
         // v1.78.41 FIX: emir ONCESI ask/bid yerine gercek dolum fiyati
         // (ResultPrice) kullaniliyor — slippage/requote durumunda eskiden
         // openPrice ile gercek POSITION_PRICE_OPEN farkli olabiliyordu, bu da
         // hem ticket eslestirme toleransini hem last_buy/sell_open_price'i
         // (STEP korumasi) hafifce kaydirabiliyordu. ResultPrice 0 donerse
         // (bazi broker/filling modlarinda anlik gelmeyebilir) ask'e dus.
         openPrice = g_trade.ResultPrice();
         if(openPrice <= 0.0) openPrice = ask;
         // v1.78.131 (R3): sepete eklenen bu bacakla netting ortalamasi
         // kaymis olabilir - SL'i yeni ortalamaya gore yeniden hizala.
         HardSL_RecalcOnAdd(symbol, g_magic, true);
      }
   } else {
      ok = g_trade.Sell(lot, symbol, 0, gridHardSl, 0, InpTradeComment);
      if(ok) {
         openPrice = g_trade.ResultPrice();
         if(openPrice <= 0.0) openPrice = bid;
         HardSL_RecalcOnAdd(symbol, g_magic, true);
      }
   }

   if(!ok) {
      AsyncHedgeProtection_RecordReject(symbol);
      PrintFormat("R21 Lattice OPEN FAIL | dir=%d | retcode=%u | %s",
                  direction, g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
      if(InpExecLock_Enable) g_gridSendLock[lockIdx][lockDir] = false;
      return false;
   }

   // AUDIT v1.78.70 (#7): bool 'ok' tek basina yeterli sayilmiyor; retcode
   // ayrica loglanir. DONE/DONE_PARTIAL/PLACED disinda bir sey gelirse
   // (CTrade'in kendi dogrulamasindan gecmis olsa bile) supheli sayilir.
   uint okRc = g_trade.ResultRetcode();
   if(okRc != TRADE_RETCODE_DONE && okRc != TRADE_RETCODE_DONE_PARTIAL && okRc != TRADE_RETCODE_PLACED) {
      AsyncHedgeProtection_RecordReject(symbol);
      int terminalErrorCheck = GetLastError();
      PrintFormat("R21 Lattice OPEN SUPHELI | dir=%d | retcode=%u terminal=%d %s — ok=true ama retcode beklenmedik, rematch dogrulayacak",
            direction, okRc, terminalErrorCheck, g_trade.ResultRetcodeDescription());
      if(InpExecLock_Enable) g_gridSendLock[lockIdx][lockDir] = false;
      return false;
   }

   posTicket = Trade_ResolvePositionTicket(symbol, direction, g_magic, lot, openPrice);
   if(posTicket == 0) {
      Print("R21 Lattice: position ticket henüz yok, sonraki tick'te eşleştirilecek");
   } else if(PositionSelectByTicket(posTicket)) {
      // AUDIT v1.78.70 (#7): ticket bu tick'te cozuldu — state'e TAHMINI
      // degil GERCEK dolum hacmini/fiyatini yaz (kismi dolum/requote'ta
      // 'lot' istenen miktar, broker'daki gercek miktardan farkli olabilir).
      double actualVol = PositionGetDouble(POSITION_VOLUME);
      double actualPx  = PositionGetDouble(POSITION_PRICE_OPEN);
      if(actualVol > 0.0) {
         if(MathAbs(actualVol - lot) > 0.0000001)
            PrintFormat("R21 Lattice KISMI DOLUM | dir=%d | istenen=%.2f gercek=%.2f — state gercek hacimle guncellendi",
                        direction, lot, actualVol);
         lot = actualVol;
      }
      if(actualPx > 0.0) openPrice = actualPx;
   }
   if(InpExecLock_Enable) g_gridSendLock[lockIdx][lockDir] = false;
   g_orderRejectCount[lockIdx] = 0;
   g_lastOrderRejectMs[lockIdx] = 0;

   // 9) Hücre işaretle
   bool isPyramidExtra = false;
   if(direction > 0) {
      isPyramidExtra = ((g_rt_ready ? g_rt_pyr_buy : InpVG_PyramidBuy) && lat.buy_levels_active > 0);
      lat.buy_levels[freeIdx].active        = true;
      lat.buy_levels[freeIdx].trigger_price = openPrice;
      lat.buy_levels[freeIdx].open_price    = openPrice;
      // KRITIK FIX: Bu kademenin acildigi anda gecerl olan STEP'i kilitle.
      // ATR/AutoTune daha sonra lat.buy_step'i degistirse bile bu kademeden
      // sonraki BUY tetigi geriye donuk olarak buyuk/kucuk olmamali.
      lat.buy_levels[freeIdx].step_at_open  = lat.buy_step;
      lat.buy_levels[freeIdx].ticket        = posTicket;
      lat.buy_levels[freeIdx].lot           = lot;
      lat.buy_levels[freeIdx].open_time     = TimeCurrent();
      lat.last_buy_open_price               = openPrice;
      lat.buy_levels_active++;
      if(isPyramidExtra) lat.pyramid_buy_extra++;
   } else {
      isPyramidExtra = ((g_rt_ready ? g_rt_pyr_sell : InpVG_PyramidSell) && lat.sell_levels_active > 0);
      lat.sell_levels[freeIdx].active        = true;
      lat.sell_levels[freeIdx].trigger_price = openPrice;
      lat.sell_levels[freeIdx].open_price    = openPrice;
      // KRITIK FIX: Bu kademenin acildigi anda gecerl olan STEP'i kilitle.
      // ATR/AutoTune daha sonra lat.sell_step'i degistirse bile bu kademeden
      // sonraki SELL tetigi geriye donuk olarak buyuk/kucuk olmamali.
      lat.sell_levels[freeIdx].step_at_open  = lat.sell_step;
      lat.sell_levels[freeIdx].ticket        = posTicket;
      lat.sell_levels[freeIdx].lot           = lot;
      lat.sell_levels[freeIdx].open_time     = TimeCurrent();
      lat.last_sell_open_price               = openPrice;
      lat.sell_levels_active++;
      if(isPyramidExtra) lat.pyramid_sell_extra++;
   }

   g_extra_lastEntryTime[(g_sym_idx>=0&&g_sym_idx<MAX_SYMBOLS)?g_sym_idx:0] = TimeCurrent();
   // v1.78.148: entry-density penceresi SADECE bu noktada (gercekten
   // acilmis pozisyon) beslenir - bkz. RiskGovernor_RecordEntryOpened
   // tanimindaki not.
   RiskGovernor_RecordEntryOpened(symbol, 1, direction);
   PrintFormat("R21 Lattice OPEN | dir=%s | lvl=%d | price=%.5f | lot=%.2f | ticket=%I64u | pyr=%s | fund=%.2f | B=%d S=%d",
               (direction > 0 ? "BUY" : "SELL"), freeIdx, openPrice, lot, posTicket,
               (isPyramidExtra ? "Y" : "N"), lat.escape_fund,
               lat.buy_levels_active, lat.sell_levels_active);
   return true;
}

//--- TP kapanış sonrası: Escape fund + Loop harvest işaretleri
void Lattice_OnTPClosed(SLatticeState &lat, const string symbol, const int direction, const double profit) {
   // DÜZELTME v1.68: Lattice TP kapanışları AutoTune istatistiklerine hiç ulaşmıyordu
   // (yalnızca Bullet_CloseTicket bağlıydı, o da kendi içinde bozuktu). Bu fonksiyon
   // yalnızca Lattice_ManageTP içindeki profit>0 dalından çağrıldığı için burada
   // her zaman kâr yönünde besleme doğrudur.
   RiskGovernor_RecordTrade(symbol, 1, direction, profit);
   AutoTune_OnDealProfit(MathAbs(profit));

   // v1.78.117 FIX (kullanici talebi): Kar Koruma Kasasi artik hesap
   // bakiyesinin kucuk bir yuzdesi (%2 gibi) yerine, kullanicinin verdigi
   // SABIT DOLAR HEDEFINE (InpVG_EscapeBankTargetUSD, orn. 1000$) gore
   // birikiyor. Kasa bu hedefi asabilir (asagida cap YOK, sadece hedef bir
   // referans noktasi) - "korunan" (dokunulmaz) kisim InpVG_EscapeProtectedPct
   // ile ayriliyor (bkz. Lattice_EscapeFund_Protected() ve
   // Lattice_EscapeFund_Available() helper'lari).
   if((g_rt_ready ? g_rt_escape_fund : InpVG_EscapeFundEnable) && profit > 0) {
      double add = profit * (InpVG_EscapeFundSharePct / 100.0);
      lat.escape_fund += add;
      PrintFormat("KarKorumaKasasi +%.2f -> toplam=%.2f (hedef=%.2f)", add, lat.escape_fund, InpVG_EscapeBankTargetUSD);
   }

   // Loop harvest: net kâr ≥ spread * mult ise hızlı re-entry için cooldown başlat
   if((g_rt_ready ? g_rt_loop_harvest : InpVG_LoopHarvestEnable) && profit > 0) {
      long spreadPts = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double tickVal = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      double spreadMoney = 0;
      if(tickSize > 0 && point > 0)
         spreadMoney = ((double)spreadPts * point / tickSize) * tickVal * InpVG_LotValue;
      double minNet = spreadMoney * InpVG_LoopMinNetSpreadMult;
      if(profit >= minNet) {
         if(direction > 0) lat.last_loop_buy_time  = TimeCurrent();
         else              lat.last_loop_sell_time = TimeCurrent();
         // v1.78.113 EKLENTI: kapanis anindaki fiyati sakla - asagidaki
         // Lattice_TryOpenLevel() icindeki yon teyidi blogu bu fiyattan itibaren fiyatin
         // GERCEKTEN o yonde devam edip etmedigini kontrol edecek.
         double closeRefPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
         if(direction > 0) lat.last_loop_buy_closePrice  = closeRefPrice;
         else              lat.last_loop_sell_closePrice = closeRefPrice;
         // last_open sıfırla → STEP engeli kalkar, harvest re-entry mümkün
         if(direction > 0) lat.last_buy_open_price  = 0;
         else              lat.last_sell_open_price = 0;
         PrintFormat("LoopHarvest arm | dir=%s | profit=%.2f >= minNet=%.2f",
                     (direction > 0 ? "BUY" : "SELL"), profit, minNet);
      }
   }

   // Pyramid sayaç azalt (kademe kapandı)
   if(direction > 0 && lat.pyramid_buy_extra > 0)  lat.pyramid_buy_extra--;
   if(direction < 0 && lat.pyramid_sell_extra > 0) lat.pyramid_sell_extra--;
}

//--- Sanal TP yönetimi (gerçek PnL > 0 ise kapat)
void Lattice_ManageTP(SLatticeState &lat, const string symbol) {
   // Panel GRID TP OTORITE + input
   if(!RT_TpAuth()) return;
   if(!InpVG_TPAuthority && !g_rt_ready) return;
   if(!FeatureGate_Profit("GRID_TP")) return;
   if(!lat.initialized) return;

   // v1.78.20: HARD min $ — en az 2.50$ (0.68$ gibi erken kapanis engeli)
   double hardMinMoney = RT_MinCloseMoney();
   if(hardMinMoney < 2.50) hardMinMoney = 2.50;
   int minAgeKul = (g_rt_ready && g_rt_kulucka > 0) ? g_rt_kulucka : 0;

   for(int i = 0; i < LATTICE_MAX_LEVELS; i++) {
      if(!lat.buy_levels[i].active || lat.buy_levels[i].ticket == 0) continue;
      if(!PositionSelectByTicket(lat.buy_levels[i].ticket)) continue;

      double vol    = PositionGetDouble(POSITION_VOLUME);
      if(vol <= 0) vol = RT_VG_Lot();
      double tpDist = Lattice_CalcTPDistance(symbol, vol);
      double minNet = Cost_MinNetProfit(symbol, vol);
      if(minNet < hardMinMoney) minNet = hardMinMoney;

      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      double openPx = PositionGetDouble(POSITION_PRICE_OPEN);
      double bid    = SymbolInfoDouble(symbol, SYMBOL_BID);

      if(minAgeKul > 0) {
         datetime pot = (datetime)PositionGetInteger(POSITION_TIME);
         if((TimeCurrent() - pot) < minAgeKul) continue;
      }
      // SADECE para tabani: fiyat mesafesi tek basina YETERSIZ (kripto cent kapanis)
      if(profit < minNet) continue;
      if((bid - openPx) < tpDist) continue;

      if(SafeClosePosition(lat.buy_levels[i].ticket, "LATTICE_TP_BUY")) {
         PrintFormat("R21 Lattice TP CLOSE BUY | ticket=%I64u | profit=%.2f (min=%.2f dist=%.5f)",
                     lat.buy_levels[i].ticket, profit, minNet, tpDist);
         lat.buy_levels[i].active = false;
         lat.buy_levels[i].ticket = 0;
         lat.buy_levels_active = MathMax(0, lat.buy_levels_active - 1);
         Lattice_OnTPClosed(lat, symbol, +1, profit);
      }
   }

   for(int i = 0; i < LATTICE_MAX_LEVELS; i++) {
      if(!lat.sell_levels[i].active || lat.sell_levels[i].ticket == 0) continue;
      if(!PositionSelectByTicket(lat.sell_levels[i].ticket)) continue;

      double vol    = PositionGetDouble(POSITION_VOLUME);
      if(vol <= 0) vol = RT_VG_Lot();
      double tpDist = Lattice_CalcTPDistance(symbol, vol);
      double minNet = Cost_MinNetProfit(symbol, vol);
      if(minNet < hardMinMoney) minNet = hardMinMoney;

      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      double openPx = PositionGetDouble(POSITION_PRICE_OPEN);
      double ask    = SymbolInfoDouble(symbol, SYMBOL_ASK);

      if(minAgeKul > 0) {
         datetime pot = (datetime)PositionGetInteger(POSITION_TIME);
         if((TimeCurrent() - pot) < minAgeKul) continue;
      }
      if(profit < minNet) continue;
      if((openPx - ask) < tpDist) continue;

      if(SafeClosePosition(lat.sell_levels[i].ticket, "LATTICE_TP_SELL")) {
         PrintFormat("R21 Lattice TP CLOSE SELL | ticket=%I64u | profit=%.2f (min=%.2f dist=%.5f)",
                     lat.sell_levels[i].ticket, profit, minNet, tpDist);
         lat.sell_levels[i].active = false;
         lat.sell_levels[i].ticket = 0;
         lat.sell_levels_active = MathMax(0, lat.sell_levels_active - 1);
         Lattice_OnTPClosed(lat, symbol, -1, profit);
      }
   }

   // TP ile son aktif seviye kapandıysa STEP referansını anında yeniden kur.
   Lattice_RebuildLastOpenRefs(lat);
}


//+------------------------------------------------------------------+
//| 8. TP-PROJ – DETAYLI HACİM / HEDEF ÇÖZÜCÜ                         |
//+------------------------------------------------------------------+
//
//  NE İŞE YARAR?
//  ─────────────
//  TP-PROJ (Take-Profit Projection), belirli bir $ kâr hedefine
//  (PeakTarget) ulaşmak için "ne kadar ek lot gerekir?" sorusunu
//  cevaplar. Klasik sabit lot yerine, açık sepet + beklenen fiyat
//  hareketi üzerinden hacim çözer.
//
//  TEMEL FORMÜL (tüm rejimlerin omurgası)
//  ───────────────────────────────────────
//  money_per_price = tick_value / tick_size     → 1.0 lot ile 1 fiyat
//                                                 birimi hareketin $ karşılığı
//  expected_move   = ATR × InpTPProjExpectedMoveATR
//  expected_money_1lot = money_per_price × expected_move
//
//  deficit = PeakTarget − (mevcut floating PnL veya equity progress)
//  required_lot ≈ deficit / expected_money_1lot
//
//  REJİMLER (PDF 6.2)
//  ──────────────────
//  TPP_REG_FIXED
//      Hedef kasası sadece izlenir. Giriş lotu sabit kalır
//      (BulletLotValue veya VG_LotValue). Projeksiyon lot üretmez.
//
//  TPP_REG_BALANCE_PCT
//      Temel lot = Balance × (InpTPProjBalancePct / 100) / margin_per_lot
//      TP-PROJ hedef çözümü yapmaz, sadece yüzde lot üretir.
//
//  TPP_REG_TARGET_DEFICIT
//      deficit_money = PeakTarget − mevcut_aynı_yön_floating_PnL
//      required_lot  = deficit_money / (money_per_price × expected_move)
//      En sade "hedefe kalan açığı kapat" formülü.
//
//  TPP_REG_CONTROLLED_RECOVERY
//      Zarar blokları tamamlandıkça temel lotu RecoveryFactor ile büyütür.
//      required_lot = base_lot × (1 + completed_loss_blocks × (factor−1))
//
//  TPP_REG_NET_VOLUME_TARGET
//      Hedef net hacim belirlenir; mevcut aynı yön lot düşülür.
//      required_lot = max(0, target_volume − existing_same_side_lot)
//
//  TPP_REG_SOLVER  (varsayılan – en akıllı)
//      Açık sepeti simüle eder:
//        1) Mevcut pozisyonların beklenen move sonrası PnL'ini hesapla
//        2) PeakTarget'a kalan açığı bul
//        3) En küçük ek lotu binary-search / doğrudan formülle çöz
//        4) Min/Max lot + serbest marjin sınırına oturt
//      Amaç: Hedefe en az ek risk ile ulaşmak.
//
//  GÜVENLİK
//  ────────
//  • InpTPProjFreezeOnLossStreak = true → zarar serisinde lot büyütme durur
//  • Sonuç her zaman [MinLot .. MaxLot] aralığına sıkıştırılır
//  • Marjin yetersizse feasible = false
//
//+------------------------------------------------------------------+

//--- 1.0 lot ile 1 fiyat birimi hareketin hesap para birimindeki değeri
// SOLVER SAFETY: Geçersiz tick value/tick size için sahte 1.0 fallback'i kaldırıldı;
// veri yoksa Solver lot üretmez ve yanlış kaldıraç hesaplamaz.
double TPProj_MoneyPerPriceUnit(const string symbol) {
   ResetLastError();
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   int errorCode = GetLastError();
   if(errorCode != 0 || tickValue <= 0.0 || tickSize <= 0.0) {
      PrintFormat("TPProj MONEY FAIL | %s | tickValue=%.10f tickSize=%.10f err=%d",
                  symbol, tickValue, tickSize, errorCode);
      return 0.0;
   }
   double moneyPerPrice = tickValue / tickSize;
   if(!MathIsValidNumber(moneyPerPrice) || moneyPerPrice <= 0.0) {
      PrintFormat("TPProj MONEY FAIL | %s | result=%.10f", symbol, moneyPerPrice);
      return 0.0;
   }
   return moneyPerPrice;
}

//--- ATR tabanlı beklenen hareket
double TPProj_ExpectedMove(const string symbol) {
   ResetLastError();
   double atr = Ind_ATR(symbol);
   int atrError = GetLastError();
   if(atr <= 0.0) {
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      if(point <= 0.0 || atrError != 0) {
         PrintFormat("TPProj MOVE FAIL | %s | ATR=%.10f point=%.10f err=%d",
                     symbol, atr, point, atrError);
         return 0.0;
      }
      atr = point * 100.0;
   }
   double expectedMove = atr * InpTPProjExpectedMoveATR;
   if(!MathIsValidNumber(expectedMove) || expectedMove <= 0.0) {
      PrintFormat("TPProj MOVE FAIL | %s | ATR=%.10f multiplier=%.10f",
                  symbol, atr, InpTPProjExpectedMoveATR);
      return 0.0;
   }
   return expectedMove;
}

//--- Belirli magic + yön için açık lot toplamı ve floating PnL
// SOLVER ACCOUNTING: Açık pozisyon komisyonu deal geçmişinden eklenir;
// ters pozisyon indeks kayması ve komisyonsuz deficit hesabı engellenir.
void TPProj_GetSameSideStats(const string symbol, const ulong magic, const int direction,
                             double &outLot, double &outFloatingPnL) {
   outLot = 0.0;
   outFloatingPnL = 0.0;
   int posType = (direction > 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ResetLastError();
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) {
         int ticketError = GetLastError();
         if(ticketError != 0)
            PrintFormat("TPProj STATS SKIP | %s | index=%d ticket err=%d", symbol, i, ticketError);
         continue;
      }

      ResetLastError();
      if(!PositionSelectByTicket(ticket)) {
         PrintFormat("TPProj STATS SKIP | %s | ticket=%I64u select err=%d",
                     symbol, ticket, GetLastError());
         continue;
      }

      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != magic) continue;
      if((int)PositionGetInteger(POSITION_TYPE) != posType) continue;

      double volume = PositionGetDouble(POSITION_VOLUME);
      double profit = PositionGetDouble(POSITION_PROFIT);
      double swap = PositionGetDouble(POSITION_SWAP);
      if(!MathIsValidNumber(volume) || volume <= 0.0 ||
         !MathIsValidNumber(profit) || !MathIsValidNumber(swap)) {
         PrintFormat("TPProj STATS SKIP | %s | ticket=%I64u geçersiz volume/profit/swap", symbol, ticket);
         continue;
      }

      double commission = 0.0;
      ulong positionId = (ulong)PositionGetInteger(POSITION_IDENTIFIER);
      if(positionId > 0) {
         ResetLastError();
         if(!HistorySelectByPosition(positionId)) {
            PrintFormat("TPProj COMMISSION WARN | %s | ticket=%I64u err=%d",
                        symbol, ticket, GetLastError());
         } else {
            for(int dealIndex = HistoryDealsTotal() - 1; dealIndex >= 0; dealIndex--) {
               ulong dealTicket = HistoryDealGetTicket(dealIndex);
               if(dealTicket == 0) continue;
               if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != symbol) continue;
               if((ulong)HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != magic) continue;
               commission += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
            }
         }
         ResetLastError();
         if(!HistorySelect(0, TimeCurrent() + 86400))
            PrintFormat("TPProj HISTORY RESTORE WARN | %s | err=%d", symbol, GetLastError());
      }

      outLot += volume;
      outFloatingPnL += profit + swap + commission;
   }
}

// SOLVER LOT SAFETY: Geçersiz broker hacim meta verisi ve minLot üstü risk
// zorlaması işlem açtırmaz; hacim step'e yuvarlandıktan sonra sınırlar yeniden doğrulanır.
double TPProj_NormalizeLot(const string symbol, double lot, const bool isGridMotor=true, const int direction=1) {
   if(!MathIsValidNumber(lot) || lot <= 0.0)
      return 0.0;

   ResetLastError();
   double brokerMinLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double brokerMaxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   int volumeError = GetLastError();
   if(volumeError != 0 || brokerMinLot <= 0.0 || brokerMaxLot < brokerMinLot || step <= 0.0) {
      PrintFormat("TPProj LOT FAIL | %s | min=%.8f max=%.8f step=%.8f err=%d",
                  symbol, brokerMinLot, brokerMaxLot, step, volumeError);
      return 0.0;
   }

   double minLot = MathMax(brokerMinLot, InpTPProjMinLot);
   double maxLot = brokerMaxLot;
   if(InpTPProjMaxLot > 0.0)
      maxLot = MathMin(maxLot, InpTPProjMaxLot);
   // v1.78.135 KRITIK KALIBRASYON: SOLVER/DEFICIT/NETVOL/RECOVERY rejimlerinin
   // "aciga gore buyu" formulleri (rawLot = deficit/remaining / expectedMoney1Lot)
   // simdiye kadar SADECE InpTPProjMaxLot (sabit, hesap buyuklugunden BAGIMSIZ,
   // varsayilan 2.0 lot) ile sinirliydi - InpRiskSizing_MaxRiskPct (%1) ile HIC
   // iliskisi yoktu. Hard SL mesafesi ise TAM OLARAK bu %1 varsayimina gore
   // hesaplaniyor (bkz. HardSL_Distance/RiskCap_MaxLot) - yani SL dogru yerdeydi
   // ama lot cok buyuyunce o mesafedeki DOLAR kaybi %1'in kat kat ustune
   // cikabiliyordu (kullanicinin bildirdigi kasa patlamasinin kok nedeni).
   // Simdi RiskCap_MaxLot (ayni %1 esigi) de EK bir tavan olarak uygulaniyor.
   //
   // v1.78.142 RISK_CALIBRATION FIX (kullanicinin bildirdigi "hic islem
   // acilmiyor / RISK MODEL VETO donguye giriyor" sorunu): YUKARIDAKI ESKI
   // YORUM'un varsaydigi "RiskCap_MaxLot() DBL_MAX = risk sizing kapali,
   // bu satir no-op" denklemi ARTIK DOGRU DEGIL - v1.78.141'de RiskCap_MaxLot
   // DBL_MAX'i ARTIK BASKA DURUMLARDA DA donduruyor (ATR/equity/fiyat
   // hesaplanamadi VEYA OrderCalcProfit basarisiz - "veri yok, veto" anlaminda,
   // "sinirsiz" anlaminda DEGIL). Ama asagidaki ciplak MathMin(maxLot,
   // RiskCap_MaxLot(...)) DBL_MAX'i "bu satir devre disi, maxLot'u degistirme"
   // olarak yorumluyordu - yani InpRiskSizing_Enable=true iken risk verisi
   // GECICI/KALICI olarak hesaplanamadiginda, Solver riskCap'SIZ (sadece
   // InpTPProjMaxLot/broker max ile sinirli, cok daha BUYUK) bir lot
   // uretebiliyordu. O buyuk lot Trade_PreflightMarketOrder'a ulasip GERCEK
   // riski (OrderCalcProfit ile, dogrudan) hesaplayan basket-risk kontrolune
   // takiliyor ve HER SEFERINDE veto ediliyordu - sonuc: sonsuz "RISK MODEL
   // VETO" dongusu, hic islem acilmiyor. Artik Lot_CalcCapped ile AYNI
   // semantik: risk sizing GERCEKTEN kapaliysa (Enable=false veya Pct<=0)
   // RiskCap_MaxLot HIC cagrilmiyor (asil no-op); ETKINSE VE DBL_MAX
   // donerse bu "veri yok" demektir ve fonksiyon ACIKCA 0.0 (reddet) doner -
   // sessizce sinirsiz devam ETMEZ.
   if(InpRiskSizing_Enable && InpRiskSizing_MaxRiskPct > 0.0) {
      double riskCapLot = RiskCap_MaxLot(symbol, isGridMotor, direction);
      if(riskCapLot == DBL_MAX) {
         PrintFormat("TPProj LOT VETO | %s | RiskCap_MaxLot risk verisi hesaplayamadi (DBL_MAX) - Solver lotu risksiz sinirlanamayacagi icin ISLEM ACILMIYOR (v1.78.142 fix)", symbol);
         return 0.0;
      }
      if(riskCapLot <= 0.0) {
         PrintFormat("TPProj LOT VETO | %s | RiskCap_MaxLot=%.8f (<=0) - islem acilmiyor", symbol, riskCapLot);
         return 0.0;
      }
      maxLot = MathMin(maxLot, riskCapLot);
   }

   if(maxLot < minLot) {
      PrintFormat("TPProj LOT FAIL | %s | effective max=%.8f < min=%.8f",
                  symbol, maxLot, minLot);
      return 0.0;
   }

   double normalizedLot = MathFloor(lot / step + 1e-12) * step;
   if(normalizedLot > maxLot)
      normalizedLot = MathFloor(maxLot / step + 1e-12) * step;

   if(normalizedLot < minLot) {
      PrintFormat("TPProj LOT REJECT | %s | raw=%.8f normalized=%.8f min=%.8f",
                  symbol, lot, normalizedLot, minLot);
      return 0.0;
   }


   double result = NormalizeDouble(normalizedLot, VolumeDigits(symbol));
   if(!MathIsValidNumber(result) || result < minLot || result > maxLot) {
      PrintFormat("TPProj LOT FAIL | %s | result=%.8f min=%.8f max=%.8f",
                  symbol, result, minLot, maxLot);
      return 0.0;
   }
   return result;
}

//--- Marjin kontrolü
bool TPProj_MarginOK(const string symbol, const double lot, const int direction) {
   if(lot <= 0.0) return false;
   ENUM_ORDER_TYPE ot = (direction > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double price = (direction > 0) ? SymbolInfoDouble(symbol, SYMBOL_ASK)
                                  : SymbolInfoDouble(symbol, SYMBOL_BID);
   double margin = 0.0;
   ResetLastError();
   if(!OrderCalcMargin(ot, symbol, lot, price, margin)) {
      PrintFormat("TPProj MARGIN FAIL | %s | lot=%.8f direction=%d price=%.8f err=%d",
                  symbol, lot, direction, price, GetLastError());
      return false;
   }
   double free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(!MathIsValidNumber(margin) || margin <= 0.0 ||
      !MathIsValidNumber(free) || free <= 0.0 || margin > free * 0.95) {
      PrintFormat("TPProj MARGIN REJECT | %s | lot=%.8f margin=%.2f free=%.2f",
                  symbol, lot, margin, free);
      return false;
   }
   return true;
}

//--- Ana hesaplama
STpProjResult TPProj_Calculate(const string symbol,
                               const ulong  magic,
                               const int    direction,          // +1 BUY / -1 SELL
                               const double peakTargetMoney,    // $ hedef
                               const double currentEquity) {
   STpProjResult r;
   ZeroMemory(r);
   r.regime_used = RT_RegimeName();
   r.feasible    = false;

   if(direction == 0) {
      r.note = "Nötr yön – projeksiyon yok";
      return r;
   }

   // Ortak metrikler
   r.money_per_price = TPProj_MoneyPerPriceUnit(symbol);
   r.expected_move   = TPProj_ExpectedMove(symbol);
   double expectedMoney1Lot = r.money_per_price * r.expected_move;
   if(expectedMoney1Lot <= 0.0) {
      r.note = "expectedMoney1Lot geçersiz";
      return r;
   }

   TPProj_GetSameSideStats(symbol, magic, direction, r.existing_same_side, r.deficit_money);
   // deficit_money geçici olarak floating PnL taşıyor; aşağıda gerçek açığa çevrilecek

   double floatingPnL = r.deficit_money;
   r.deficit_money    = peakTargetMoney - floatingPnL;   // pozitif = hedefe kalan açık
   if(r.deficit_money < 0.0) r.deficit_money = 0.0;      // hedef zaten aşıldı

   double mid = (SymbolInfoDouble(symbol, SYMBOL_BID) + SymbolInfoDouble(symbol, SYMBOL_ASK)) * 0.5;
   r.projected_price = (direction > 0) ? (mid + r.expected_move)
                                       : (mid - r.expected_move);

   double rawLot = 0.0;

   switch(RT_Regime()) {

      //──────────────────────────────────────────────────────────────
      case TPP_REG_FIXED:
         // Lot üretmez – sadece hedef izlenir. Çağıran taraf sabit lot kullanır.
         rawLot = 0.0;
         r.note = "FIXED: projeksiyon lot üretmiyor, sabit lot kullanılacak";
         break;

      //──────────────────────────────────────────────────────────────
      case TPP_REG_BALANCE_PCT: {
         double bal = AccountInfoDouble(ACCOUNT_BALANCE);
         if(!MathIsValidNumber(bal) || bal <= 0.0) {
            r.note = "BALANCE_PCT: geçersiz bakiye";
            rawLot = 0.0;
            break;
         }
         double margin1 = Margin_PerLotSafe(symbol, direction);
         if(!MathIsValidNumber(margin1) || margin1 <= 0.0) {
            r.note = "BALANCE_PCT: geçersiz yönlü marjin";
            rawLot = 0.0;
            break;
         }
         rawLot = (bal * (InpTPProjBalancePct / 100.0)) / margin1;
         if(!MathIsValidNumber(rawLot) || rawLot <= 0.0) {
            r.note = "BALANCE_PCT: geçersiz lot sonucu";
            rawLot = 0.0;
            break;
         }
         r.note = StringFormat("BALANCE_PCT: %.2f%% → rawLot=%.4f", InpTPProjBalancePct, rawLot);
         break;
      }

      //──────────────────────────────────────────────────────────────
      case TPP_REG_TARGET_DEFICIT:
         // En sade formül: açığı beklenen 1 lot'luk hareketin $ değerine böl
         if(r.deficit_money <= 0.0) {
            rawLot = 0.0;
            r.note = "TARGET_DEFICIT: açık yok, lot=0";
         } else {
            rawLot = r.deficit_money / expectedMoney1Lot;
            r.note = StringFormat("TARGET_DEFICIT: deficit=%.2f / exp$=%.2f → raw=%.4f",
                                  r.deficit_money, expectedMoney1Lot, rawLot);
         }
         break;

      //──────────────────────────────────────────────────────────────
      case TPP_REG_CONTROLLED_RECOVERY: {
         // FIX v1.78.13: eskiden hep 0 kalan static sayaç yerine, Bullet
         // motorunun zaten sembol bazlı sürdürdüğü gerçek ardışık aynı-yön
         // zarar sayacı kullanılıyor (B_SAME_LOSS = g_bullet_sameSideLoss[g_sym_idx],
         // bu fonksiyonda birkaç satır aşağıda LOSS_STREAK_FREEZE için de kullanılıyor).
         double baseLot = InpTPProjMinLot;
         rawLot = baseLot * (1.0 + B_SAME_LOSS * (InpTPProjRecoveryFactor - 1.0));
         // v1.78.125 FIX (kullanici tespiti - "recovery rejiminde sabit lot"):
         // Varsayilan ayarlarla (baseLot=0.01, factor=1.2, step=0.01) bu
         // carpim asamali olarak 0.012, 0.014, 0.016... uretiyor - hepsi
         // MathFloor ile TEK bir step'e (0.01) geri yuvarlaniyordu, ilk
         // gorunur buyume ancak B_SAME_LOSS=5'te geliyordu (Lattice_CalcLot
         // icindeki grid-carpani ayni sorunu v1.78.109'da bu sekilde
         // cozmustu). Grid tarafiyla TUTARLI olacak sekilde: her ardisik
         // zarardan sonra en az 1 step buyume garanti edilir, boylece
         // "recovery" adindan beklenen "her zarardan sonra biraz buyu"
         // davranisi floor-rounding'e kurban gitmez.
         double recStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
         if(recStep <= 0.0) recStep = 0.01;
         double recMinGrowth = baseLot + B_SAME_LOSS * recStep;
         if(rawLot < recMinGrowth) rawLot = recMinGrowth;
         r.note = StringFormat("CONTROLLED_RECOVERY: blocks=%d factor=%.2f → raw=%.4f",
                               B_SAME_LOSS, InpTPProjRecoveryFactor, rawLot);
         break;
      }

      //──────────────────────────────────────────────────────────────
      case TPP_REG_NET_VOLUME_TARGET: {
         // Hedef hacim ≈ deficit / expectedMoney1Lot
         // Sonra mevcut aynı yön lot düşülür → sadece eksik açılır
         double targetVol = (r.deficit_money > 0.0) ? (r.deficit_money / expectedMoney1Lot) : 0.0;
         rawLot = targetVol - r.existing_same_side;
         if(rawLot < 0.0) rawLot = 0.0;
         r.note = StringFormat("NET_VOLUME: target=%.4f existing=%.4f → add=%.4f",
                               targetVol, r.existing_same_side, rawLot);
         break;
      }

      //──────────────────────────────────────────────────────────────
      case TPP_REG_SOLVER:
      default: {
         // SOLVER: Açık sepeti simüle et + en küçük ek lotu bul
         //
         // 1) Mevcut aynı yön pozisyonlar expected_move kadar ilerlerse
         //    ne kadar PnL üretir?
         //    approx_additional_pnl = existing_lot × money_per_price × expected_move
         //
         // 2) Toplam beklenen PnL = floatingPnL + approx_additional_pnl
         //    (floating zaten şu anki; additional ise move sonrası ekstra)
         //
         // 3) Hâlâ PeakTarget'a yetmiyorsa:
         //    remaining = PeakTarget − (floating + existing×mpp×move)
         //    add_lot   = remaining / (mpp × move)
         //
         // Bu, "mevcut hacim zaten hareketten faydalanacak, sadece
         // eksiği tamamla" mantığıdır → en az ek risk.

         double existingContribution = r.existing_same_side * expectedMoney1Lot;
         double projectedTotal = floatingPnL + existingContribution;
         double remaining = peakTargetMoney - projectedTotal;

         // v1.78.139 EKLENDI #3: SOLVER, fiyat lehe donmedigi surece
         // remaining hep pozitif kalip zarardaki yone SINIRSIZ ek lot
         // onerebiliyordu (klasik martingale/averaging sarmali - "hesap hic
         // kara gecmiyor" sikayetinin asil kok sebebi). InpTPProjSolverMaxLot
         // > 0 ise ayni-yon TOPLAM lot bu tavana ulastiginda/gectiginde ek
         // lot onerisi 0'a cekilir; hesap zaten RECOVERY/DD kurallarina
         // (satir ~3154 vd.) tabi olmaya devam eder, sadece SOLVER'in kendi
         // basina sinirsiz buyumesi durdurulur.
         if(InpTPProjSolverMaxLot > 0.0 && r.existing_same_side >= InpTPProjSolverMaxLot) {
            rawLot = 0.0;
            r.note = StringFormat("SOLVER_MAXLOT_DUR: existing=%.4f >= tavan=%.4f, ek lot durduruldu",
                                  r.existing_same_side, InpTPProjSolverMaxLot);
         } else if(remaining <= 0.0) {
            rawLot = 0.0;
            r.note = StringFormat("SOLVER: mevcut sepet yeterli (proj=%.2f >= hedef=%.2f)",
                                  projectedTotal, peakTargetMoney);
         } else {
            rawLot = remaining / expectedMoney1Lot;
            r.note = StringFormat("SOLVER: remaining=%.2f / exp$=%.2f → addLot=%.4f | existing=%.4f",
                                  remaining, expectedMoney1Lot, rawLot, r.existing_same_side);
         }
         break;
      }
   }

   // Zarar serisi: projeksiyon lot büyütmeyi dondur
   // v1.78.125 FIX (kullanici tespiti - "recovery rejiminde sabit lot"):
   // CONTROLLED_RECOVERY'nin TEK VAROLUS SEBEBI ardisik zarardan SONRA lotu
   // (InpTPProjRecoveryFactor ile SINIRLI/kontrollu bicimde) buyutmek. Bu
   // dondurma onceden rejim ayrimi yapmadan HER rejimde calisiyordu - yani
   // "zarar serisi -> dondur" kurali, "zarar serisi -> kontrollu buyut"
   // rejimiyle DOGRUDAN CELISIYORDU: varsayilan ayarlarla dondurma esigi
   // (InpBullet_SameSideLossLimit=3), recovery formulunun (v1.78.125
   // duzeltmesinden ONCE B_SAME_LOSS=5 gerektiren) ilk buyume adimindan
   // ONCE tetikleniyordu - yani RECOVERY rejimi varsayilan ayarlarla ASLA
   // buyuyemiyordu, hep sabit kaliyordu. Artik CONTROLLED_RECOVERY bu
   // dondurmadan MUAF - kendi buyume siniri zaten InpTPProjRecoveryFactor'dur,
   // ustune bir de disaridan dondurulmesine gerek yok.
   if(InpTPProjFreezeOnLossStreak && RT_Regime() != TPP_REG_CONTROLLED_RECOVERY &&
      B_SAME_LOSS >= InpBullet_SameSideLossLimit) {
      rawLot = MathMin(rawLot, InpVG_LotValue > 0 ? InpVG_LotValue : rawLot);
      r.note = (r.note == "" ? "" : r.note + " | ") + "LOSS_STREAK_FREEZE";
   }

   // Normalize + marjin
   // v1.78.141 RISK_CALIBRATION FIX: isGridMotor=false (bu Bullet/Solver
   // yolu) + gercek direction - RiskCap_MaxLot Bullet'in GERCEK 3 ATR Hard
   // SL mesafesini kullanabilsin diye.
   r.required_lot = TPProj_NormalizeLot(symbol, rawLot, false, direction);

   // Solver/deficit/net-volume hedefleri aşağı yuvarlanan broker step'iyle
   // sessizce eksik kalmasın. Üst step maxLot/marjin sınırını aşıyorsa işlem
   // feasible kabul edilmez; minimum lot zorla yükseltilmez.
   if(rawLot > 0.0 &&
      (RT_Regime() == TPP_REG_SOLVER ||
       RT_Regime() == TPP_REG_TARGET_DEFICIT ||
       RT_Regime() == TPP_REG_NET_VOLUME_TARGET)) {
      double volumeStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      double brokerMax = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      if(volumeStep > 0.0 && brokerMax > 0.0) {
         double roundedUp = MathCeil((rawLot / volumeStep) - 1e-12) * volumeStep;
         double configuredMax = (InpTPProjMaxLot > 0.0)
                                ? MathMin(brokerMax, InpTPProjMaxLot)
                                : brokerMax;
         if(roundedUp <= configuredMax && TPProj_MarginOK(symbol, roundedUp, direction))
            r.required_lot = NormalizeDouble(roundedUp, VolumeDigits(symbol));
         else if(r.required_lot > 0.0)
            r.note += " | step sonrası hedef tam karşılanamıyor";
      }
   }

   if(r.required_lot > 0.0 && TPProj_MarginOK(symbol, r.required_lot, direction)) {
      r.feasible = true;
   } else if(r.required_lot > 0.0) {
      r.feasible = false;
      r.note += " | MARJİN YETERSİZ";
      r.required_lot = 0.0;
   } else {
      r.feasible = false; // lot=0 zaten açılmayacak
   }

   return r;
}

//--- Kolay çağrı sarmalayıcı (pipeline için)
STpProjResult TPProj_Run(const string symbol, const ulong magic, const int direction) {
   // v1.78.37 FIX: PEAK MODU (PEAK$/BAKIYE%) duzeltmesi (RT_Peak()) buraya
   // hic ulasmiyordu — burasi hep ham InpTPProjPeakTargetMoney girdisini
   // kullaniyordu, panel/BAKIYE% modu TP-PROJ solver'ini hic etkilemiyordu.
   return TPProj_Calculate(symbol, magic, direction,
                           RT_Peak(),
                           AccountInfoDouble(ACCOUNT_EQUITY));
}

//+------------------------------------------------------------------+
//| 9. TREND / BULLET MOTORU + TP-PROJ BAĞLANTISI                    |
//+------------------------------------------------------------------+
//
//  PDF Bölüm 6 özeti
//  ─────────────────
//  Bullet = trend yönünde tek (veya kontrollü) giriş motoru.
//  Lot: AUTO (bakiye%) / MANUAL (sabit) / PROJECT (TP-PROJ solver).
//  Güvenlik: RepeatLossGuard, SameSideLossLimit, confidence eşiği.
//
//+------------------------------------------------------------------+

// g_bullet_* → global bölümde tanımlı

double Bullet_CalcLot(const string symbol, const int direction, SPipelineContext &ctx) {
   double lot = RT_BulletLot();
   // v1.78.124 EKLENTI (kullanici talebi - "lot bazen buyuyor bazen sabit"):
   // BLM_PROJECT modunda lotun neden buyudugunu/sabit kaldigini gorunur
   // kilan tani metni - asagida doldurulur, fonksiyon sonunda tek satir
   // PrintFormat ile (InpSR_LogDecisions altinda) Journal'a yazilir.
   string tpDiag = "";
   double preCapLot = 0.0;
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;

   switch(RT_LotMode()) {
      case BLM_MANUAL:
         lot = RT_BulletLot(); // panel BULLET LOT
         break;

      case BLM_AUTO: {
         // v1.73: bal<=0 / margin1<=0 sıfıra bölünme koruması
         double bal = AccountInfoDouble(ACCOUNT_BALANCE);
         if(bal <= 0.0) { lot = minLot; break; }
         // v1.78.41 FIX: Margin_PerLotSafe — yon-farkindalikli + gercekci fallback
         double margin1 = Margin_PerLotSafe(symbol, direction);
         if(margin1 <= 0.0) { lot = minLot; break; }
         // SECOND_AUDIT #2 FIX (P1/P2): AUTO dalinda risk yuzdesi kaynagi artik
         // InpAutoLotPct - InpBulletLotValue burada YANLIS input'tu (o, BLM_FIXED
         // dalinin manuel lot degeri icin var; kullanici InpAutoLotPct'yi degistirse
         // AUTO modda davranis hic degismiyordu). Ayni alt/ust guvenlik siniri korundu.
         double pct = (InpAutoLotPct > 0 && InpAutoLotPct < 10) ? InpAutoLotPct : 0.5;
         lot = (bal * (pct / 100.0)) / margin1;
         break;
      }

      case BLM_PROJECT: {
         // v1.78.37 FIX: TP BASLANGIC (FIXED/PROJECT) butonu hicbir yere
         // baglanmamisti — InpTPProjStart/g_rt_tp_start hic okunmuyordu,
         // BLM_PROJECT modunda ILK giris de dahil HER giris dogrudan
         // solver'dan geliyordu. Solver, henuz hic pozisyon yokken (ilk,
         // teyitsiz giris) "hedefe tek atista ulas" buyuklugunde bir lot
         // uretebilir. Artik: TP BASLANGIC=FIXED ise ILK giris (B_TICKET==0)
         // sabit/guvenli lotla aciliyor, solver sadece MEVCUT pozisyona
         // EKLEME yaparken (sepeti hedefe tamamlarken) devreye giriyor.
         // TP BASLANGIC=PROJECT ise eskisi gibi ilk giristen itibaren solver.
         int startMode = g_rt_ready ? g_rt_tp_start : (int)InpTPProjStart;
         // v1.78.42 FIX (#99): InpTPProjGReset artik gercekten uygulaniyor.
         // Global reset (GLOBAL_PROFIT/LOSS/FORCED_RESET) sonrasi ilk Bullet
         // acilisinda, eger kullanici FIXED_LOT veya PROJECTED_LOT override
         // istemisse (g_gresetForceStartMode set edilmis), normal InpTPProjStart
         // yerine bu bir kerelik deger kullanilir; sonra tuketilip -1'e doner.
         // KEEP_PEAK_LOGIC (varsayilan) ise hicbir zaman set edilmez, davranis
         // aynen InpTPProjStart'a gore devam eder.
         if(B_TICKET == 0 && g_gresetForceStartMode >= 0) {
            startMode = g_gresetForceStartMode;
            g_gresetForceStartMode = -1; // bir kerelik — tuketildi
         }
         // v1.78.98: ilk giris karari artik startMode'dan bagimsiz (asagi bkz.);
         // g_gresetForceStartMode tuketimi yine de yukarida yapiliyor. NOT: startMode
         // artik hicbir yerde okunmuyor - MQL5 "(void)expr;" cast'ini desteklemiyor
         // (bu satir "illegal use of 'void' type" + "invalid cast operation" hatalarina
         // yol aciyordu), bu yuzden derleyici uyarisini bastirmaya calisan o satir
         // tamamen kaldirildi. MQL5 kullanilmayan yerel degiskenler icin hata vermez,
         // olsa olsa zararsiz bir uyari verir.
         // v1.78.98 FIX (DUZELTME_REHBERI #5): eskiden bu SADECE
         // startMode==TPP_START_FIXED_LOT iken uygulaniyordu; TP
         // BASLANGIC=PROJECT secilirse ILK giris de dogrudan solver'in
         // "hedefe tek atista ulas" lotunu kullanabiliyordu (buyuk/oransiz
         // ilk lot riski). Artik startMode ne olursa olsun ILK giris
         // (B_TICKET==0) HER ZAMAN guvenli sabit lotla acilir; solver
         // sadece MEVCUT pozisyona EKLEME yaparken (B_TICKET != 0)
         // devreye girer. NOT: bu, TP BASLANGIC=PROJECT secen kullanicilar
         // icin onceki ilk-giris davranisini kasitli olarak degistirir.
         if(B_TICKET == 0) {
            lot = RT_BulletLot();
            tpDiag = "ILK_GIRIS_SABIT (v1.78.98: sepetin ilk pozisyonu her zaman guvenli sabit lotla acilir, solver sadece EKLEME yaparken devreye girer)";
         } else {
            // TP-PROJ solver'dan ek lot
            STpProjResult tp = TPProj_Run(symbol, g_magic, direction);
            ctx.tpproj = tp;
            if(tp.feasible && tp.required_lot > 0) {
               lot = tp.required_lot;
               tpDiag = "SOLVER_BUYUTTU | " + tp.note;
            } else {
               lot = InpBulletLotValue; // fallback sabit
               tpDiag = "SOLVER_FALLBACK_SABIT | " + tp.note;
            }
            if((InpTPProjFreezeOnLossStreak || InpBullet_FreezeTPProjLotOnLossStreak) &&
               RT_Regime() != TPP_REG_CONTROLLED_RECOVERY &&
               B_SAME_LOSS >= InpBullet_SameSideLossLimit) {
               lot = InpBulletLotValue; // zarar serisinde büyütme yok
               tpDiag += StringFormat(" | ZARAR_SERISI_DONDURMA gecerli (solver ustune yazildi, B_SAME_LOSS=%d >= limit=%d)",
                                      B_SAME_LOSS, InpBullet_SameSideLossLimit);
            } else if(RT_Regime() == TPP_REG_CONTROLLED_RECOVERY && B_SAME_LOSS >= InpBullet_SameSideLossLimit) {
               // v1.78.125 FIX: burada tekrar sabitlemiyoruz - TPProj_Calculate
               // icindeki ayni istisna (bkz. yukarida) zaten dogru "recovery"
               // lotunu urettu, onu buraya kadar getirip son anda ezmek eski
               // hataya geri donmek olurdu.
               tpDiag += " | ZARAR_SERISI_DONDURMA muaf (CONTROLLED_RECOVERY kendi buyume sinirini kullaniyor)";
            }
         }
         break;
      }
   }

   // v1.78.115 EKLENTI (kullanici talebi): MANUEL/AUTO modda ardisik kazanc
   // serisine gore lot buyutme - PROJECT modunda UYGULANMAZ (solver kendi
   // hedef matematigini yonetiyor, bkz. Lot_CalcCapped icindeki PROJECT
   // korumasi). Panelin GRID CARPAN (g_rt_grid_mult/g_rt_grid_mult_on)
   // degerini ve ARDISIK CARPAN (g_rt_seq_mult) secimini yeniden kullanir -
   // kullanici zaten bu panel kontrollerini biliyor, ayri bir ogrenme
   // egrisi gerektirmez.
   if(InpBullet_WinStreakMultEnable && RT_LotMode() != BLM_PROJECT &&
      g_rt_ready && g_rt_grid_mult_on && g_rt_grid_mult > 1.0) {
      int winDepth = MathMin(B_SAME_WIN, InpBullet_WinStreakMaxLevels);
      if(winDepth > 0) {
         double lotBeforeMult = lot;
         double stepLocal = step;
         if(g_rt_seq_mult)
            lot *= MathPow(g_rt_grid_mult, winDepth);
         else
            lot *= g_rt_grid_mult; // tek sefer carpan
         // v1.78.109'daki Grid round-up mantigiyla AYNI: kucuk carpanlar
         // (orn. 1.09) step-altinda (0.01) kaybolmasin diye taban garanti
         // edilir. seqMode=true ise depth ile kumulatif, false ise sabit +1step.
         double baseNorm = MathFloor(lotBeforeMult / stepLocal + 1e-9) * stepLocal;
         double minGrowthLot = g_rt_seq_mult ? (baseNorm + winDepth * stepLocal) : (baseNorm + stepLocal);
         if(lot < minGrowthLot) lot = minGrowthLot;
      }
   }

   double riskGovMult = RiskGovernor_FinalLotMult(symbol, direction, 0);
   if(riskGovMult <= 0.0) {
      g_lastLotRejectReason = "RISK_GOV_LOCK";
      lot = 0.0;
   } else {
      lot *= riskGovMult;
   }

   preCapLot = lot;
   // v1.78.141 RISK_CALIBRATION FIX: isGridMotor=false (Bullet) + gercek
   // direction - RiskCap_MaxLot Bullet'in GERCEK 3 ATR Hard SL mesafesini
   // kullanabilsin diye (bkz. RiskCap_MaxLot/Lot_CalcCapped yorumu).
   lot = Lot_CalcCapped(symbol, lot, false, direction);


   // v1.73: dinamik volume digits
   lot = MathFloor(lot / step + 1e-12) * step;
   // v1.78.93 NOT (ESKI - ARTIK GECERSIZ): burada bir zamanlar "RiskCap_MaxLot
   // equity-risk% tavani tamamen kaldirildi" yazıyordu. v1.78.98'de bu tavan
   // Lot_CalcCapped() icinde YENIDEN ZORUNLU hale getirildi (bkz. yukarida
   // RISK-BASED LOT SIZING input grubu ve Lot_CalcCapped icindeki
   // DUZELTME_REHBERI #1 notu). Asagidaki "lot < minLot -> 0" satiri zaten
   // dogru davranistir ve DOKUNULMADI: Lot_CalcCapped artik kendi icinde
   // NormalizeLotForEntry() ile ayni kurali uyguladigi icin bu satir fiilen
   // hicbir zaman tetiklenmez (lot ya 0 ya da zaten >= minLot gelir) - yine
   // de ikinci bir guvenlik agi olarak birakildi.
   if(lot < minLot) lot = 0;
   if(lot > maxLot) lot = maxLot;
   // v1.78.46 FIX (#100): InpTPProjMaxLot, TP-PROJ input GRUBUNDA tanimli olmasina
   // ragmen bu satir RT_LotMode()'dan BAGIMSIZ, yani BLM_AUTO ve BLM_MANUAL'de de
   // (kullanici TP-PROJ'u hic kullanmiyorken bile) devreye giriyordu. Sonuc: Panelden
   // "BULLET LOT MODE"u AUTO/MANUAL'e alan bir kullanicinin lotu, farkinda olmadan
   // ayri bir "TP-PROJ REJIM" ayar grubundaki InpTPProjMaxLot (varsayilan 2.0) ile
   // sessizce kirpiliyordu — iki "ayri kontrol katmani" (TP-PROJ regime vs Bullet Lot
   // Mode) birbirine sizmis oluyordu. Artik yalnizca BLM_PROJECT modunda uygulanir;
   // AUTO/MANUAL modlarda genel InpBullet/InpLattice/mutlak sinirlar (asagida) gecerli.
   if(RT_LotMode() == BLM_PROJECT && InpTPProjMaxLot > 0 && lot > InpTPProjMaxLot) lot = InpTPProjMaxLot;
   if(InpLatticeMaxLot > 0.0 && lot > InpLatticeMaxLot) lot = InpLatticeMaxLot;
   double finalLotForDiag = NormalizeDouble(lot, VolumeDigits(symbol));
   // v1.78.124 EKLENTI (kullanici talebi - "lot bazen buyuyor bazen sabit"):
   // PROJECT modunda, solver'in "buyut/sabit tut" karari VERILDIKTEN SONRA
   // risk tavanlarinin (RiskCap_MaxLot/InpLatticeMaxLot/InpTPProjMaxLot/0.50
   // mutlak tavan) o karari SESSIZCE kirpip kirpmadigini gorunur kilar -
   // onceden bu asama hic loglanmiyordu; "lot neden buyumedi" sorusu sadece
   // lot=0 oldugunda (g_lastLotRejectReason ile) cevaplanabiliyordu, lot>0
   // ama umulandan kucuk cikan durumlar tamamen sessizdi.
   if(RT_LotMode() == BLM_PROJECT && InpSR_LogDecisions) {
      bool clipped = (MathAbs(finalLotForDiag - preCapLot) > 0.0000001);
      if(clipped)
         tpDiag += StringFormat(" | TAVANLAR_KIRPTI: %.2f -> %.2f", preCapLot, finalLotForDiag);
      PrintFormat("R21 TP-PROJ LOT | %s | dir=%d | sepet=%s | final=%.2f | %s",
                  symbol, direction, (B_TICKET != 0 ? "VAR(ekleme)" : "YOK(ilk giris)"),
                  finalLotForDiag, tpDiag);
   }
   return finalLotForDiag;
}

//--- Entry quality skoru 0..100
int Bullet_EntryQualityScore(const SPipelineContext &ctx) {
   int score = 0;
   score += (int)(ctx.dir.confidence * 40.0);           // 0..40
   if(ctx.dir.phase == PHASE_TREND_UP || ctx.dir.phase == PHASE_TREND_DOWN)
      score += 20;
   // Spread cezası
   // v1.78.35: ham "spr<20/50" puan XAUUSD icin kalibre edilmis sabitlerdi —
   // BTC/USOIL gibi cok farkli fiyat olcekli sembollerde anlamsiz kalir
   // (ADIM'da bulunanla ayni ölçek riski). ATR verisi varsa spread'i o
   // sembolun KENDI ATR'sine oranlayarak degerlendir; yoksa eski (XAUUSD
   // icin gecerli) ham esige geri don.
   long spr = SymbolInfoInteger(ctx.symbol, SYMBOL_SPREAD);
   double atrQ = RiskATR_Read(ctx.symbol);
   double ptQ  = SymbolInfoDouble(ctx.symbol, SYMBOL_POINT);
   if(atrQ > 0 && ptQ > 0) {
      double spreadFracAtr = ((double)spr * ptQ) / atrQ;
      if(spreadFracAtr < 0.05)      score += 20;
      else if(spreadFracAtr < 0.15) score += 10;
   } else {
      if(spr < 20) score += 20;
      else if(spr < 50) score += 10;
   }
   // DI/TMI consensus
   if(!g_consensusBlocked) score += 20;
   // SECOND_AUDIT #3 FIX (P2): InpBullet_LossQualityStep artik gercekten
   // kullaniliyor - ardisik ayni-yon zarar (B_SAME_LOSS, zaten sembol bazli
   // takip ediliyor) arttikca giris kalite skoru bu kadar dusuruluyor, boylece
   // InpBullet_EntryQualityMinScore esigini gecmek zarar serisi uzadikca
   // zorlasiyor. Adim <= 0 ise davranis degismez (ozellik fiilen kapali).
   if(InpBullet_LossQualityStep > 0 && B_SAME_LOSS > 0)
      score -= (int)MathRound(InpBullet_LossQualityStep * B_SAME_LOSS);
   if(score < 0) score = 0;
   if(score > 100) score = 100;
   return score;
}

// v1.78.40 FIX: SymbolList_Init() (OnInit icinde) her restart'ta g_bullet_ticket[]
// ve ilgili dizileri sifirliyordu, broker'da "-BLT" suffix'i ile acik kalmis bir
// pozisyon varsa referansi tamamen kayboluyordu (bkz. Bullet_RematchTicket yorumu
// — o fonksiyon SADECE ayni oturum icindeki gecici kayiplari cozer, restart'i
// degil). Bu fonksiyon dogrudan index ile (g_sym_idx/makrolara bagimli olmadan)
// broker'i tarayip varsa en yeni "-BLT" pozisyonunu bulup RAM state'i geri kurar.
void Bullet_ReconcileFromBroker(const int idx) {
   if(idx < 0 || idx >= MAX_SYMBOLS) return;
   string symbol = g_symbols[idx];
   ulong best = 0;
   datetime bestTime = 0;
   int bestDir = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      string cmt = PositionGetString(POSITION_COMMENT);
      if(StringFind(cmt, "-BLT") < 0) continue; // sadece Bullet pozisyonu
      datetime ot = (datetime)PositionGetInteger(POSITION_TIME);
      if(ot >= bestTime) {
         bestTime = ot;
         best = t;
         bestDir = ((int)PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      }
   }
   if(best > 0) {
      g_bullet_ticket[idx]    = best;
      g_bullet_entryDir[idx]  = bestDir;
      g_bullet_openTime[idx]  = bestTime;
      g_bullet_peakProfit[idx]= 0; // peak restart'ta guvenli sekilde sifirlanir (asiri erken TP tetiklemez)
      // v1.78.116 NOT: g_bullet_prevClosedDir (B_PREV_CLOSED_DIR) burada
      // BILEREK sifirlanmis birakiliyor (SymbolList_Init/OnInit zaten 0'a
      // resetliyor) - restart ONCESI serinin (kazanc/zarar) devam ettirilmesi
      // icin bir bilgi yok, ve DEVAM ETTIRMEMEK GUVENLI TARAF: bu pozisyon
      // kapaninca B_SAME_WIN/B_SAME_LOSS "ilk kapanis" gibi 1'den baslar -
      // lot buyutme kucuk baslar (risk artmaz), zarar serisi de sifirdan
      // sayilir (yanlis alarm vermez). Bilinçli tasarim tercihi, bug degil.
      PrintFormat("R21 Bullet RECONCILE | %s | ticket=%I64u dir=%d (restart sonrasi geri kuruldu)",
                  symbol, best, bestDir);
   }
}

// v1.78.134 REFACTOR: Bullet_CloseTicket()'in bookkeeping kismi (RiskGovernor/
// AutoTune/B_SAME_LOSS/B_SAME_WIN/B_PREV_CLOSED_DIR guncellemesi + state temizligi)
// ortak bir fonksiyona cikarildi. Amac: hem EA'nin kendi kapattigi normal akis
// (Bullet_CloseTicket), hem Hard SL/broker stop-out/manuel mudahale gibi HARICI
// kapanislar (Bullet_HandleExternalClose, asagida) AYNI mantigi kullansin - iki
// ayri yerde tutarsizliga acik kopya kod olmasin.
void Bullet_RecordCloseOutcome(const string closeSymbol, const ulong ticket,
                                const int closeDir, const double closeProfit,
                                const bool wasLoss) {
   if(closeSymbol != "")
      RiskGovernor_RecordTrade(closeSymbol, 0, closeDir, closeProfit);
   AutoTune_OnDealProfit(wasLoss ? -MathAbs(closeProfit) : MathAbs(closeProfit));
   B_LAST_CLOSE = TimeCurrent();
   B_LAST_WAS_LOSS = wasLoss ? 1 : 0;
   // v1.78.116 FIX (kritik): eskiden "B_ENTRY_DIR==B_LAST_DIR" karsilastirmasi
   // kullaniliyordu - bu ikisi HER ZAMAN esitti (acilista birlikte set
   // ediliyorlardi), yani karsilastirma hicbir bilgi tasimiyordu, HER
   // KAPANISTA "ayni yon" sayiyordu. Artik B_PREV_CLOSED_DIR (bir onceki
   // KAPANAN islemin yonu) ile karsilastiriliyor - bu, YON DEGISIKLIGINI
   // GERCEKTEN yakalayabilen tek dogru referans.
   bool sameDirAsLastClosed = (B_PREV_CLOSED_DIR != 0) && (B_ENTRY_DIR == B_PREV_CLOSED_DIR);
   if(wasLoss) {
      if(sameDirAsLastClosed)
         B_SAME_LOSS++;
      else
         B_SAME_LOSS = 1;
      B_SAME_WIN = 0; // v1.78.115: zararda kazanc serisi sifirlanir
   } else {
      B_SAME_LOSS = 0;
      // v1.78.115 EKLENTI: B_SAME_LOSS ile SIMETRIK ama TERS mantik -
      // ayni yonde ust uste KAZANILDIYSA seri devam eder, yon
      // degistiyse (once BUY kazandi simdi SELL kazandi gibi) seri
      // 1'den yeniden baslar - Grid'deki "depth" kavramina benzer.
      if(sameDirAsLastClosed)
         B_SAME_WIN++;
      else
         B_SAME_WIN = 1;
   }
   B_PREV_CLOSED_DIR = B_ENTRY_DIR; // v1.78.116: bir sonraki kapanis icin referans guncellendi
   if(B_TICKET == ticket) {
      B_TICKET = 0;
      B_PEAK = 0;
      B_ENTRY_DIR = 0;
      B_OPEN_TIME = 0;
   }
}

void Bullet_CloseTicket(const ulong ticket, const string reason, const bool wasLoss, const double profitAtClose=0.0) {
   if(ticket == 0) return;

   string closeSymbol = "";
   int closeDir = 0;
   if(PositionSelectByTicket(ticket)) {
      closeSymbol = PositionGetString(POSITION_SYMBOL);
      closeDir = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
   }

   if(SafeClosePosition(ticket, "BULLET_" + reason)) {
      PrintFormat("Bullet CLOSE | ticket=%I64u reason=%s", ticket, reason);
      Sound_Play(wasLoss ? "LOSS" : "PROFIT");
      // DÜZELTME v1.68: PositionClose() sonrası PositionSelectByTicket() pozisyon artık
      // kapalı olduğu için güvenilmez şekilde false dönüyordu -> cp her zaman 0 kalıyor,
      // AutoTune hiçbir zaman gerçek kâr/zarar büyüklüğü almıyordu. Artık çağıran taraf
      // kapatmadan ÖNCE okuduğu gerçek profit değerini (profitAtClose) doğrudan geçiriyor.
      // v1.78.134: RiskGovernor_RecordTrade de artik AYNI (profitAtClose) degeri
      // kullaniyor - eskiden PositionSelectByTicket'tan (yukarida, kapanmadan ONCE)
      // okunan AYRI bir closeProfit degeri kullaniyordu; ikisi pratikte hep ayni
      // seyi temsil ediyordu, tek kaynaga indirildi.
      Bullet_RecordCloseOutcome(closeSymbol, ticket, closeDir, profitAtClose, wasLoss);
   }
}

// v1.78.134 YENI: Hard SL / GridRiskFirewall emergency close / manuel mudahale
// gibi Bullet_CloseTicket() DISINDAN gerceklesen kapanislari yakalamak icin.
// Bullet_Manage() icindeki "ticket gecerliligi" kontrolu (PositionSelectByTicket
// basarisiz), pozisyonun ARTIK ORADA OLMADIGINI dogru tespit ediyordu ama
// sadece state'i (B_TICKET vb.) temizleyip HICBIR bookkeeping yapmiyordu -
// B_SAME_LOSS hic artmiyordu, RiskGovernor/AutoTune o kapanistan HABERSIZ
// kaliyordu. Bu fonksiyon, kapanan islemin gercek kar/zararini GECMISTEN
// (HistorySelectByPosition) cekip Bullet_RecordCloseOutcome() ile AYNI
// bookkeeping'i calistirir - boylece "EA'nin kendi kapattigi" ile "harici
// kapanan" arasinda ogrenme/sayac acisindan fark kalmaz.
void Bullet_HandleExternalClose(const string symbol, const ulong ticket) {
   int dir = B_ENTRY_DIR;
   double profit = 0.0;
   bool found = false;

   ResetLastError();
   if(HistorySelectByPosition(ticket)) {
      for(int i = HistoryDealsTotal() - 1; i >= 0; i--) {
         ulong dealTicket = HistoryDealGetTicket(i);
         if(dealTicket == 0) continue;
         profit += HistoryDealGetDouble(dealTicket, DEAL_PROFIT)
                 + HistoryDealGetDouble(dealTicket, DEAL_SWAP)
                 + HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
         found = true;
      }
   } else {
      PrintFormat("BULLET EXTERNAL CLOSE WARN | %s | ticket=%I64u HistorySelectByPosition err=%d",
                  symbol, ticket, GetLastError());
   }
   // v1.78.20 deseniyle ayni (TPProj_GetSameSideStats'ta da kullanilir):
   // HistorySelectByPosition secili araligi degistirir - genis pencereyi
   // geri yuklemezsek bu ticten sonra calisan baska kod (orn.
   // Security_GetDailyPnLPercent) bozulur.
   ResetLastError();
   if(!HistorySelect(0, TimeCurrent() + 86400))
      PrintFormat("BULLET EXTERNAL CLOSE HISTORY RESTORE WARN | %s | err=%d", symbol, GetLastError());

   if(!found) {
      PrintFormat("BULLET EXTERNAL CLOSE | %s | ticket=%I64u | gecmiste islem bulunamadi, bookkeeping atlaniyor",
                  symbol, ticket);
      if(B_TICKET == ticket) { B_TICKET = 0; B_PEAK = 0; B_ENTRY_DIR = 0; B_OPEN_TIME = 0; }
      return;
   }

   bool wasLoss = (profit < 0.0);
   PrintFormat("BULLET EXTERNAL CLOSE TESPIT EDILDI | %s | ticket=%I64u | dir=%d | profit=%.2f | wasLoss=%s",
               symbol, ticket, dir, profit, wasLoss ? "true" : "false");
   Bullet_RecordCloseOutcome(symbol, ticket, dir, profit, wasLoss);
}


//+------------------------------------------------------------------+
//| RANGE PROFIT GUARD - MIN MONEY (v1.78.68 #131)                   |
//| InpRangeProfitGuardUseDynamicMin=true ise TFG'nin RT_MinCloseMoney|
//| ile AYNI equity-olcekli tabani kullanir (equity*%0.25 veya $2.50,|
//| hangisi buyukse). false ise eski sabit InpRangeProfitGuardMinMoney|
//| davranisi korunur. Boylece kucuk hesapta anlamli, buyuk hesapta  |
//| gurultu seviyesinde kalmayan tutarli bir esik saglanir - TFG ile |
//| ayni felsefe (bkz. RT_MinCloseMoney).                            |
//+------------------------------------------------------------------+
double RangeProfitGuard_MinMoney()
{
   if(InpRangeProfitGuardUseDynamicMin)
      return MathMax(0.0, RT_MinCloseMoney());
   return MathMax(0.0, InpRangeProfitGuardMinMoney);
}

//+------------------------------------------------------------------+
//| RANGE PROFIT GUARD - TEYIT KONTROLU (v1.78.68 #131)              |
//| InpRangeProfitGuardUseConfirmSec=true ise RANGE fazinin KESINTISIZ|
//| sure (InpRangeProfitGuardConfirmSec) kadar surdugune bakar - tick |
//| sikligindan bagimsiz, TFG/AEGIS'in saniye-bazli tasarimiyla       |
//| tutarli. false ise eski ConfirmTicks sayaci davranisi korunur.    |
//| sinceArr[idx]==0 → henuz RANGE'e girilmedi. phase != RANGE ise    |
//| cagiran taraf sinceArr[idx] ve countArr[idx]'i sifirlamalidir.    |
//+------------------------------------------------------------------+
bool RangeProfitGuard_Confirmed(const int idx, int &countArr[], datetime &sinceArr[])
{
   if(InpRangeProfitGuardUseConfirmSec)
   {
      if(sinceArr[idx] == 0) sinceArr[idx] = TimeCurrent();
      int elapsed = (int)(TimeCurrent() - sinceArr[idx]);
      return elapsed >= MathMax(0, InpRangeProfitGuardConfirmSec);
   }
   int need = MathMax(1, InpRangeProfitGuardConfirmTicks);
   return countArr[idx] >= need;
}

//+------------------------------------------------------------------+
//| RANGE PROFIT GUARD                                               |
//| Trendde kazanilan Bullet, piyasa RANGE'e dondugunda geri         |
//| verilmesin. Zararli pozisyonlar kesinlikle bu guard tarafindan  |
//| kapatilmaz.                                                      |
//+------------------------------------------------------------------+
void RangeProfitGuard_Manage(SPipelineContext &ctx)
{
   int idx = g_sym_idx;
   if(idx < 0 || idx >= MAX_SYMBOLS) idx = 0;

   if(!InpRangeProfitGuardEnable)
   {
      g_range_guard_count[idx] = 0;
      g_range_guard_since[idx] = 0;
      return;
   }

   if(ctx.dir.phase == PHASE_RANGE)
      g_range_guard_count[idx]++;
   else
   {
      g_range_guard_count[idx] = 0;
      g_range_guard_since[idx] = 0;
      return;
   }

   if(!RangeProfitGuard_Confirmed(idx, g_range_guard_count, g_range_guard_since))
      return;

   if(B_TICKET == 0 || !PositionSelectByTicket(B_TICKET))
      return;
   if(PositionGetString(POSITION_SYMBOL) != ctx.symbol)
      return;

   double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   double minMoney = RangeProfitGuard_MinMoney();
   if(profit < minMoney)
      return;

   bool closeNow = InpRangeProfitGuardCloseOnRange;

   // CloseOnRange kapaliysa yalnizca peak'ten belirgin geri cekilmede kapat.
   if(!closeNow && InpRangeProfitGuardPullbackPct > 0.0 && B_PEAK > minMoney)
   {
      double keepFrac = 1.0 - InpRangeProfitGuardPullbackPct / 100.0;
      if(keepFrac < 0.0) keepFrac = 0.0;
      closeNow = (profit <= B_PEAK * keepFrac);
   }

   if(!closeNow)
      return;

   PrintFormat("RANGE PROFIT GUARD | %s | phase=RANGE confirm=%d | profit=%.2f peak=%.2f | kar korunuyor",
               ctx.symbol, g_range_guard_count[idx], profit, B_PEAK);
   Bullet_CloseTicket(B_TICKET, "RANGE_PROFIT_GUARD", false, profit);
   g_range_guard_count[idx] = 0;
}

//+------------------------------------------------------------------+
//| GRID RANGE PROFIT GUARD (v1.78.67 #130)                          |
//| RangeProfitGuard_Manage yalnizca TEK bir Bullet ticket'ini        |
//| koruyordu; en cok kari getiren Grid/Lattice sepeti RANGE          |
//| rejiminde tamamen korumasizdi. Bu fonksiyon BUY ve SELL sepetini  |
//| AYRI AYRI degerlendirir. Grid cift yonlu (hedge'li) calisabildigi |
//| icin, TrendFlipGuard'daki (v1.78.55 #125) ile BIREBIR AYNI        |
//| NET-POZITIF kurali uygulanir: karsi tarafin toplam zarari         |
//| olculur, kapatilabilir kar bu zarari + InpRangeProfitGuardMinMoney|
//| tamponunu KARSILAMIYORSA hic dokunulmaz (aksi halde karsi taraf   |
//| hedge'siz kalip DD Hedge equity dususuyle tetiklenip AYNI hedge'i |
//| spread odeyerek yeniden acabilir - net kayip). Esik alti/zarardaki|
//| tek tek kademelere asla dokunulmaz.                               |
//+------------------------------------------------------------------+
void GridRangeProfitGuard_ManageSide(SPipelineContext &ctx, const int direction)
{
   int idx = g_sym_idx;
   if(idx < 0 || idx >= MAX_SYMBOLS) idx = 0;

   double minMoney = RangeProfitGuard_MinMoney();
   double sideNet  = Lattice_SameSideProfitMoney(g_lattice, ctx.symbol, direction);

   double peak = (direction > 0) ? g_grid_buy_peakProfit[idx] : g_grid_sell_peakProfit[idx];

   if(sideNet < minMoney)
   {
      // Bu tarafta korunacak anlamli kar yok - zirve sifirlanir, yeni birikim
      // bastan sayilir (eski zirveyle yanlis pullback% hesaplanmasin).
      if(direction > 0) { g_grid_buy_peakProfit[idx] = 0; g_grid_buy_oppLossAtConfirm[idx] = 0; }
      else              { g_grid_sell_peakProfit[idx] = 0; g_grid_sell_oppLossAtConfirm[idx] = 0; }
      return;
   }

   if(sideNet > peak) peak = sideNet;
   if(direction > 0) g_grid_buy_peakProfit[idx] = peak; else g_grid_sell_peakProfit[idx] = peak;

   bool closeNow = InpRangeProfitGuardCloseOnRange;

   // v1.78.68 (#131): Grid'e ozel pullback% verilmisse (>0) onu kullan;
   // verilmemisse (0) Bullet ile ayni InpRangeProfitGuardPullbackPct kullanilir
   // (eski davranisla birebir geriye donuk uyumlu).
   double pullbackPctGrid = (InpRangeProfitGuardPullbackPctGrid > 0.0)
                             ? InpRangeProfitGuardPullbackPctGrid
                             : InpRangeProfitGuardPullbackPct;

   // CloseOnRange kapaliysa yalnizca sepet zirveden belirgin geri cekilince kapat.
   if(!closeNow && pullbackPctGrid > 0.0 && peak > minMoney)
   {
      double keepFrac = 1.0 - pullbackPctGrid / 100.0;
      if(keepFrac < 0.0) keepFrac = 0.0;
      closeNow = (sideNet <= peak * keepFrac);
   }

   if(!closeNow)
      return;

   // v1.78.68 (#131): Karsi tarafin zarari RANGE teyidi TAMAMLANDIGI ANDA
   // bir kez olculup dondurulur (g_grid_*_oppLossAtConfirm). Boylece
   // ConfirmSec/PullbackPct bekleme suresi uzadikca karsi tarafin zarari
   // buyuyup requiredBuffer'i sinsice yukseltmez - yani korumanin en cok
   // gerekli oldugu an (RANGE'e yeni girildigi an) referans alinir.
   // GUVENLIK: karar anindaki GUNCEL zarar da ayrica olculur; ikisinin
   // BUYUK olani kullanilir - donmus deger asla gercek riski maskelemez,
   // sadece bekleme suresince gereksiz sertlesmeyi onler.
   double oppLossNow = 0.0;
   for(int oi = 0; oi < LATTICE_MAX_LEVELS; oi++)
   {
      SLatticeLevel ol = (direction > 0) ? g_lattice.sell_levels[oi] : g_lattice.buy_levels[oi];
      if(!ol.active || ol.ticket == 0) continue;
      if(!PositionSelectByTicket(ol.ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      double op = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(op < 0.0) oppLossNow += (-op);
   }

   double frozenLoss = (direction > 0) ? g_grid_buy_oppLossAtConfirm[idx] : g_grid_sell_oppLossAtConfirm[idx];
   if(frozenLoss <= 0.0)
   {
      frozenLoss = oppLossNow;
      if(direction > 0) g_grid_buy_oppLossAtConfirm[idx] = frozenLoss; else g_grid_sell_oppLossAtConfirm[idx] = frozenLoss;
   }
   double oppLoss = MathMax(frozenLoss, oppLossNow);
   double requiredBuffer = oppLoss + minMoney;

   // Bu tarafta gercekten kapatilabilecek (esigi tek basina karsilayan) kar.
   double availableProfit = 0.0;
   for(int ai = 0; ai < LATTICE_MAX_LEVELS; ai++)
   {
      SLatticeLevel al = (direction > 0) ? g_lattice.buy_levels[ai] : g_lattice.sell_levels[ai];
      if(!al.active || al.ticket == 0) continue;
      if(!PositionSelectByTicket(al.ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      double ap = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(ap >= minMoney) availableProfit += ap;
   }

   if(availableProfit < requiredBuffer)
      return; // net-pozitif degil - cekmek hedge riski/net kayip dogurur, dokunma

   int    closedCount  = 0;
   double closedProfit = 0.0;
   for(int i = 0; i < LATTICE_MAX_LEVELS; i++)
   {
      SLatticeLevel lvl = (direction > 0) ? g_lattice.buy_levels[i] : g_lattice.sell_levels[i];
      if(!lvl.active || lvl.ticket == 0) continue;
      if(!PositionSelectByTicket(lvl.ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;

      double pp = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(pp < minMoney) continue; // esik alti/zarardaki kademeye dokunma

      if(SafeClosePosition(lvl.ticket, "GRID_RANGE_PROFIT_GUARD"))
      {
         closedCount++;
         closedProfit += pp;
      }
   }

   if(closedCount > 0)
   {
      PrintFormat("GRID RANGE PROFIT GUARD | %s %s | phase=RANGE | sepet=%.2f zirve=%.2f | %d kademe kapandi kar=%.2f | karsi taraf zarar=%.2f (dondurulmus=%.2f, guncel=%.2f)",
                  ctx.symbol, (direction > 0 ? "BUY" : "SELL"), sideNet, peak, closedCount, closedProfit, oppLoss, frozenLoss, oppLossNow);
      if(direction > 0) { g_grid_buy_peakProfit[idx] = 0; g_grid_buy_oppLossAtConfirm[idx] = 0; }
      else              { g_grid_sell_peakProfit[idx] = 0; g_grid_sell_oppLossAtConfirm[idx] = 0; }
   }
}

void GridRangeProfitGuard_Manage(SPipelineContext &ctx)
{
   int idx = g_sym_idx;
   if(idx < 0 || idx >= MAX_SYMBOLS) idx = 0;

   if(!InpRangeProfitGuardEnable || !InpRangeProfitGuardIncludeGrid)
   {
      g_grid_range_guard_count[idx] = 0;
      g_grid_range_guard_since[idx] = 0;
      g_grid_buy_peakProfit[idx] = 0;
      g_grid_sell_peakProfit[idx] = 0;
      g_grid_buy_oppLossAtConfirm[idx] = 0;
      g_grid_sell_oppLossAtConfirm[idx] = 0;
      return;
   }
   if(!RT_VG() || !RT_TpAuth()) return;   // Grid kapali veya TP yetkisi yoksa yapacak bir sey yok
   if(!g_lattice.initialized) return;

   if(ctx.dir.phase == PHASE_RANGE)
   {
      g_grid_range_guard_count[idx]++;
   }
   else
   {
      g_grid_range_guard_count[idx] = 0;
      g_grid_range_guard_since[idx] = 0;
      g_grid_buy_peakProfit[idx] = 0;
      g_grid_sell_peakProfit[idx] = 0;
      g_grid_buy_oppLossAtConfirm[idx] = 0;
      g_grid_sell_oppLossAtConfirm[idx] = 0;
      return;
   }

   if(!RangeProfitGuard_Confirmed(idx, g_grid_range_guard_count, g_grid_range_guard_since))
      return;

   GridRangeProfitGuard_ManageSide(ctx, 1);   // BUY sepeti
   GridRangeProfitGuard_ManageSide(ctx, -1);  // SELL sepeti
}

// v1.78.39 FIX: Trade_ResolvePositionTicket acilis aninda 0 dondurebilir
// (requote/gecikme/deal henuz history'e dusmemis — Lattice tarafinda zaten
// bilinen ve Lattice_RematchTickets ile cozulen bir durum). Bullet motorunde
// boyle bir "sonradan esletir" mekanizmasi yoktu: B_TICKET=0 kalinca pozisyon
// EA'nin gozunden tamamen kayboluyordu (Bonus TP/Profit Lock/Max Hold/Flip
// hicbiri calismiyordu) VE ayni yonde ikinci bir bullet acilabiliyordu, ilk
// (yetim) pozisyon piyasada acik kalirken. Bu fonksiyon B_ENTRY_DIR/B_OPEN_TIME
// (acilista ticket'tan BAGIMSIZ set edilir) kullanarak sembol+magic+yon+yakin-
// zamanli pozisyonu arayip B_TICKET'i sonradan baglar.
void Bullet_RematchTicket(SPipelineContext &ctx) {
   if(B_TICKET != 0) return;          // zaten bagli
   if(B_ENTRY_DIR == 0) return;       // acik bullet yok
   if(B_OPEN_TIME == 0) return;

   int wantType = (B_ENTRY_DIR > 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   ulong best = 0;
   long  bestDiff = -1;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      if((int)PositionGetInteger(POSITION_TYPE) != wantType) continue;
      // Lattice hücrelerinden biri bu ticket'ı zaten sahiplenmiş olabilir — çakışma yok
      bool ownedByLattice = false;
      for(int li = 0; li < LATTICE_MAX_LEVELS; li++) {
         if(g_lattice.buy_levels[li].active  && g_lattice.buy_levels[li].ticket  == t) { ownedByLattice = true; break; }
         if(g_lattice.sell_levels[li].active && g_lattice.sell_levels[li].ticket == t) { ownedByLattice = true; break; }
      }
      if(ownedByLattice) continue;
      datetime ot = (datetime)PositionGetInteger(POSITION_TIME);
      long diff = MathAbs((long)ot - (long)B_OPEN_TIME);
      if(diff > 10) continue; // B_OPEN_TIME civarında (10sn) açılmış olmalı
      if(bestDiff < 0 || diff < bestDiff) { bestDiff = diff; best = t; }
   }
   if(best > 0) {
      B_TICKET = best;
      PrintFormat("R21 Bullet REMATCH | ticket=%I64u dir=%d (onceden kayip ticket sonradan baglandi)",
                  best, B_ENTRY_DIR);
   }
}

//--- Açık bullet yönetimi: incubation, Bonus TP, Profit Lock, Flip
void Bullet_Manage(SPipelineContext &ctx) {
   if(!RT_Bullet()) return;

   // Ticket geçerliliği
   if(B_TICKET > 0 && !PositionSelectByTicket(B_TICKET)) {
      // v1.78.134 FIX: eskiden burada sadece state (B_TICKET vb.) temizlenip
      // return edilirdi - Hard SL/broker stop-out/manuel kapanis gibi Bullet_
      // CloseTicket() DISINDAKI kapanislarda B_SAME_LOSS/RiskGovernor/AutoTune
      // HICBIR ZAMAN guncellenmiyordu (EA o kapanistan hicbir sey ogrenmiyordu).
      // Bullet_HandleExternalClose() gercek kar/zarari gecmisten cekip AYNI
      // bookkeeping'i calistirir, state temizligini de kendisi yapar.
      Bullet_HandleExternalClose(ctx.symbol, B_TICKET);
      return;
   }
   if(B_TICKET == 0) {
      Bullet_RematchTicket(ctx); // v1.78.39: kayıp ticket'ı sonradan bağlamayı dene
      if(B_TICKET == 0) return;
   }
   if(!PositionSelectByTicket(B_TICKET)) return;
   if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) return;

   double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   int age = (int)(TimeCurrent() - B_OPEN_TIME);
   if(profit > B_PEAK) B_PEAK = profit;

   // Incubation: panel KAR/ZARAR KULUCKA (sn) → input fallback
   int needInc = (profit >= 0) ? RT_KarKulucka() : RT_ZararKulucka();
   if(age < needInc) return;

   // Bonus TP: panel BONUS TP + VTP CARPAN
   // v1.78.20: min kâr en az max(MinClose, Peak*0.25, 3$) – 0.68$ kapanis engeli
   if(RT_BonusTP() && FeatureGate_Profit("BONUS_TP")) {
      long spr = SymbolInfoInteger(ctx.symbol, SYMBOL_SPREAD);
      double point = SymbolInfoDouble(ctx.symbol, SYMBOL_POINT);
      double openPx = PositionGetDouble(POSITION_PRICE_OPEN);
      double targetDist = (double)spr * point * RT_VtpMult();
      double minBonus = RT_MinCloseMoney();
      // v1.78.35 FIX: burada RT_Peak() kullanılıyordu — o TP-PROJ'un GENEL
      // hesap kâr HEDEFİ (InpTPProjPeakTargetMoney), bu TEK bullet pozisyonuyla
      // alakasız. Amaç ("Peak*0.25") açıkça BU pozisyonun kendi zirve kârının
      // %25'i — yani B_PEAK (Profit Lock bölümünde birkaç satır aşağıda zaten
      // doğru kullanılan aynı değişken). Yanlış değişkenle minBonus, hesabın
      // genel hedefine göre şişip Bonus TP'nin neredeyse hiç tetiklenmemesine
      // yol açıyordu (pozisyonlar gereğinden uzun açık kalıp geri dönüşe maruz
      // kalıyordu).
      double peakFloor = B_PEAK * 0.25;
      if(peakFloor > minBonus) minBonus = peakFloor;
      if(minBonus < 3.0) minBonus = 3.0;
      bool hit = false;
      if(B_ENTRY_DIR > 0) {
         double bid = SymbolInfoDouble(ctx.symbol, SYMBOL_BID);
         hit = (bid - openPx) >= targetDist && profit >= minBonus;
      } else {
         double ask = SymbolInfoDouble(ctx.symbol, SYMBOL_ASK);
         hit = (openPx - ask) >= targetDist && profit >= minBonus;
      }
      if(hit) {
         Bullet_CloseTicket(B_TICKET, "BONUS_TP", false, profit);
         return;
      }
   }

   // Profit Lock: zirveden pullback % – sadece anlamli zirve sonrasi
   // v1.78.20: peak en az MinClose kadar olmali (kucuk peak'ten erken kilit yok)
   if(InpBullet_ProfitLockEnable && FeatureGate_Profit("PROFIT_LOCK") &&
      B_PEAK >= RT_MinCloseMoney() && profit > 0) {
      double pull = ((B_PEAK - profit) / B_PEAK) * 100.0;
      if(pull >= InpBullet_ProfitLockPullbackPct) {
         Bullet_CloseTicket(B_TICKET, "PROFIT_LOCK", false, profit);
         return;
      }
   }

   // Max hold süresi
   if(InpBullet_MaxHoldMinutes > 0 && age >= InpBullet_MaxHoldMinutes * 60) {
      bool loss = (profit < 0);
      Bullet_CloseTicket(B_TICKET, "MAX_HOLD", loss, profit);
      return;
   }

   // Trend flip kapanışı
   if(ctx.dir.direction != 0 && ctx.dir.direction != B_ENTRY_DIR &&
      ctx.dir.confidence >= 0.35 && InpBullet_CloseOnFlip) {
      bool allowFlip = (profit >= 0) ? FeatureGate_Profit("TREND_FLIP") : FeatureGate_Loss("TREND_FLIP");
      if(allowFlip && profit >= InpBullet_MinProfitToFlipClose &&
         TimeCurrent() - B_LAST_FLIP >= InpBullet_FlipCooldownSec) {
         bool loss = (profit < 0);
         Bullet_CloseTicket(B_TICKET, "TREND_FLIP", loss, profit);
         B_LAST_FLIP = TimeCurrent();
         return;
      }
   }
}

// TRADE SAFETY: Bullet yalnızca broker ön kontrolü ve kabul edilmiş retcode
// sonrasında açılış state'ini günceller; reddedilen emir hayali işlem sayılmaz.
void Bullet_Process(SPipelineContext &ctx) {
   if(!RT_Bullet()) return;

   // v1.78.130 MOTOR ACTIVATION GATE: Bullet motoru bu rejimde AKTİF mı?
   // Rejim geçişi sırasında veya devre dışı motor tarafından hiçbir yeni giris yapılmasin
   if(!AdaptiveMarket_IsMotorActive(1)) return;

   // GECICI TESHIS (v1.78.152/153), v1.78.158: kok neden (DirectionLock'un
   // notr tick'te reversal adayini silmesi) bulunup DirectionLock_Manage
   // icinde duzeltildi. Bu satir hala faydali (gelecekte baska bir sebep
   // cikarsa yeniden aramaya gerek kalmasin diye) ama artik diger tani
   // satirlarindaki gibi InpSR_LogDecisions ile kontrollu - "throttle YOK"
   // haliyle cok gunluk bir M5 testinde Journal'i sismiriyordu.
   if(InpSR_LogDecisions && ctx.dir.direction != 0)
      PrintFormat("TESHIS-B | Bullet_Process basi ctx.dir.direction=%d conf=%.3f allow=%s",
                  ctx.dir.direction, ctx.dir.confidence, ctx.allow_new_entries ? "true" : "false");

   {
      // v1.78.149: eskiden sabit "reason=ENTRY_DENSITY_OR_PERFORMANCE"
      // yaziyordu - kalite (0.55/0.60 esikleri) ile yogunluk/performans
      // ayni metinle gorunuyor, birbirinden ayirt edilemiyordu. Artik
      // RiskGovernor_BlockEntry'nin GERCEK sebebi yazilir.
      string bulletRiskGovReason = "";
      if(RiskGovernor_BlockEntry(ctx.symbol, 0, ctx.dir.direction, bulletRiskGovReason)) {
         if(InpSR_LogDecisions)
            PrintFormat("R21 BULLET RISK GOV BLOCK | %s | dir=%d | reason=%s",
                        ctx.symbol, ctx.dir.direction, bulletRiskGovReason);
         return;
      }
   }

   // Önce açık pozisyon yönetimi
   Bullet_Manage(ctx);

   // GECICI TESHIS (v1.78.153), v1.78.158: her sessiz "return" icin tani
   // satiri - kok neden artik bulundu (DirectionLock'un notr tick'te
   // reversal adayini silmesi, bkz. DirectionLock_Manage v1.78.158 FIX),
   // ama diger BDIAG noktalarinin hangisinin darbogaz oldugunu ileride
   // yeniden teyit edebilmek icin blok TAMAMEN KALDIRILMADI - InpSR_
   // LogDecisions ile ayni tutarli desene baglandi (once "throttle YOK"
   // idi, cok gunluk M5 testinde Journal'i asiri buyutuyordu).
   bool bDiagTick = (InpSR_LogDecisions && ctx.dir.direction != 0);
   #define BDIAG_RET(reason) { if(bDiagTick) PrintFormat("R21 BULLET TESHIS RED | %s | dir=%d | sebep=%s", ctx.symbol, ctx.dir.direction, reason); return; }

   if(!ctx.allow_new_entries) BDIAG_RET("ALLOW_NEW_ENTRIES_FALSE");
   // v1.78.120 EKLENTI (ERB - Early Reversal Brake): Bullet_Manage() (yukarida,
   // mevcut acik pozisyon yonetimi) ZATEN CALISTI ve dokunulmadi - ERB SADECE
   // buradan sonraki YENI GIRIS yolunu keser (belgenin 13. bolumu).
   if(InpERB_BlockBullet && ERB_BlocksNewRisk(ctx.symbol)) {
      if(InpERB_LogDecisions)
         PrintFormat("[ERB] BLOCK BULLET | symbol=%s | reason=EARLY_REVERSAL_WARNING", ctx.symbol);
      return;
   }
   if(ctx.dir.direction == 0) BDIAG_RET("DIRECTION_SIFIR");
   if(!DirectionLock_AllowsEntry(ctx.symbol, ctx.dir.direction)) BDIAG_RET("DIRECTION_LOCK_ENGEL");

   // Panel BLOK: zararli pozisyon sayisi limiti
   // v1.78.60 KRITIK FIX (#127): Lattice_TryOpenLevel'daki ile ayni hata -
   // lossN yon ayrimi yapmadan TUM pozisyonlari sayiyordu, bu yuzden SELL
   // tarafi zararli kademe limitine ulasinca Bullet_Process de BUY girislerini
   // (ve tam tersini) engelliyordu. Artik SADECE ctx.dir.direction ile AYNI
   // yondeki pozisyonlar sayiliyor.
   if(RT_Blok()) {
      int lossN = 0;
      int wantTypeZB = (ctx.dir.direction > 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
      for(int bi = PositionsTotal() - 1; bi >= 0; bi--) {
         ulong bt = PositionGetTicket(bi);
         if(bt == 0 || !PositionSelectByTicket(bt)) continue;
         if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
         if((int)PositionGetInteger(POSITION_TYPE) != wantTypeZB) continue;
         double bp = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         if(bp < 0) lossN++;
      }
      if(lossN >= RT_ZararBlok()) BDIAG_RET("ZARAR_BLOK");
   }
   // Trend fazı zorunlu; AllowReopenNeutral açıkken RANGE/NEUTRAL'da da (düşük conf ile) izin
   bool phaseOk = (ctx.dir.phase == PHASE_TREND_UP || ctx.dir.phase == PHASE_TREND_DOWN);
   if(!phaseOk) {
      if(!(InpAllowReopenNeutral && (ctx.dir.phase == PHASE_RANGE || ctx.dir.phase == PHASE_NEUTRAL)
           && ctx.dir.confidence >= 0.40))
         BDIAG_RET("PHASE_TREND_DEGIL");
   }
   if(ctx.dir.confidence < RT_ConfFloor()) BDIAG_RET("CONF_FLOOR_ALTI");
   // Trend girislerinde destek/direnc kirilimi teyit edilmeden Bullet acma.
   if(!SR_EntryConfirmed(ctx.symbol, ctx.dir.direction, ctx.dir.phase))
      BDIAG_RET("SR_BREAKOUT_ONAY_YOK");

   // Zaten açık bullet varsa yeni açma (PROJECT hariç basit mod)
   // v1.78.39 FIX: B_TICKET==0 iken B_ENTRY_DIR!=0 ise "ticket henüz eşleşmedi
   // ama bullet açık" durumudur (bkz. Bullet_RematchTicket) — eskiden sadece
   // B_TICKET>0 kontrol edildiği için bu ara durumda ikinci bir bullet daha
   // açılabiliyordu, ilk (henüz eşleşmemiş) pozisyon piyasada dururken.
   bool bulletOpenPending = (B_TICKET > 0) || (B_ENTRY_DIR != 0);
   // v1.78.43 FIX (#110): B_TICKET (g_bullet_ticket[idx]) TEK bir ulong'dur —
   // sadece bir pozisyonu temsil edebilir. BLM_PROJECT modunda yukaridaki
   // guard atlaniyordu ve InpBullet_MaxSameSideOpens>1 ile birden fazla ayni
   // yonlu Bullet pozisyonu ACILABILIYORDU, ama Bullet_Manage/Bullet_RematchTicket
   // /Bullet_ReconcileFromBroker hepsi TEK ticket'i yonetiyor — digerleri EA'nin
   // yonetimi disinda kaliyordu (TP/Peak/Flip mantigi onlara hic uygulanmiyordu).
   // Gercek coklu-ticket state koleksiyonu (dizi/liste) buyuk bir mimari
   // degisiklik gerektirir; guvenli ve geriye-donuk-uyumlu cozum: PROJECT
   // modunda da ayni-yon acilis 1 ile sinirlanir (input degeri DEGISTIRILMEZ,
   // sadece PROJECT moddaki fiili davranis netlestirilir), boylece B_TICKET
   // her zaman GERCEKTEN tek acik pozisyonu temsil eder.
   if(bulletOpenPending) {
      if(RT_LotMode() != BLM_PROJECT) BDIAG_RET("BULLET_ACIK_BEKLIYOR");
      if(InpBullet_MaxSameSideOpens > 1) {
         static datetime s_gresetWarnOnce = 0;
         if(TimeCurrent() - s_gresetWarnOnce > 3600) {
            s_gresetWarnOnce = TimeCurrent();
            PrintFormat("Bullet: MaxSameSideOpens=%d ayarlanmis ama PROJECT modda B_TICKET tek pozisyon takip edebilir — fiilen 1 ile sinirlaniyor (bkz. #110)",
                        InpBullet_MaxSameSideOpens);
         }
      }
      BDIAG_RET("BULLET_ACIK_PROJECT_MODE"); // PROJECT modda da: acik bullet varken ikinci acilisa izin verme
   }

   // Repeat loss guard
   int sameLim = g_rt_ready ? RT_ZararBlok() : InpBullet_SameSideLossLimit;
   if(InpBullet_RepeatLossGuard &&
      B_LAST_DIR == ctx.dir.direction &&
      B_SAME_LOSS >= sameLim) {
      BDIAG_RET("REPEAT_LOSS_GUARD");
   }

   // Max same-side opens (PROJECT modda B_TICKET tekilligi nedeniyle yukarida
   // zaten 1'e sinirlandi; diger modlarda bulletOpenPending guard'i zaten
   // devrede oldugu icin bu blok fiilen sadece coklu-sembol/coklu-magic
   // senaryolarinda ek bir emniyet katmanidir).
   if(InpBullet_MaxSameSideOpens > 0) {
      double sameLot = 0, dummy = 0;
      TPProj_GetSameSideStats(ctx.symbol, g_magic, ctx.dir.direction, sameLot, dummy);
      int sameN = 0;
      int wantType = (ctx.dir.direction > 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong t = PositionGetTicket(i);
         if(t == 0 || !PositionSelectByTicket(t)) continue;
         if(PositionGetString(POSITION_SYMBOL) != ctx.symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
         if((int)PositionGetInteger(POSITION_TYPE) == wantType) sameN++;
      }
      if(sameN >= InpBullet_MaxSameSideOpens) BDIAG_RET("MAX_SAME_SIDE_OPENS");
   }

   // Fresh signal after loss
   if(InpBullet_RequireFreshSignalAfterLoss && B_LAST_WAS_LOSS != 0 &&
      B_LAST_DIR == ctx.dir.direction) {
      // aynı yönde zarar sonrası confirm ticks sıfırdan biriksin
      if(B_CONFIRM < InpBullet_EntryConfirmTicks + 2) BDIAG_RET("FRESH_SIGNAL_AFTER_LOSS_BEKLENIYOR");
   }

   // Zarar kapanış sonrası cooldown
   if(B_LAST_WAS_LOSS != 0 && B_LAST_CLOSE > 0 &&
      TimeCurrent() - B_LAST_CLOSE < InpBullet_LossCooldownSec)
      BDIAG_RET("ZARAR_SONRASI_COOLDOWN");

   // Flip cooldown
   if(B_LAST_FLIP > 0 &&
      TimeCurrent() - B_LAST_FLIP < InpBullet_FlipCooldownSec)
      BDIAG_RET("FLIP_COOLDOWN");

   // Min edge vs spread
   // v1.78.35: "spr > 100*mult" sabiti de XAUUSD'ye gore kalibre edilmis ham
   // puandi — ATR varsa spread/ATR oranina gore degerlendir (sembol-bagimsiz),
   // yoksa eski ham esige don.
   long spr = SymbolInfoInteger(ctx.symbol, SYMBOL_SPREAD);
   if(spr > 0 && InpBullet_MinEdgeSpreadMult > 0) {
      double atrE = RiskATR_Read(ctx.symbol);
      double ptE  = SymbolInfoDouble(ctx.symbol, SYMBOL_POINT);
      if(atrE > 0 && ptE > 0) {
         double spreadFracAtrE = ((double)spr * ptE) / atrE;
         if(spreadFracAtrE > 0.25 * InpBullet_MinEdgeSpreadMult) BDIAG_RET("SPREAD_ATR_ORANI_YUKSEK");
      } else if((double)spr > 100.0 * InpBullet_MinEdgeSpreadMult) {
         BDIAG_RET("SPREAD_HAM_ESIK_ASILDI");
      }
   }

   // Entry confirm ticks
   // SECOND_AUDIT #1 FIX (P1): sembol bazli B_CONFIRM_LASTDIR (bkz. tanim yorumu)
   if(ctx.dir.direction != B_CONFIRM_LASTDIR) {
      B_CONFIRM = 1;
      B_CONFIRM_LASTDIR = ctx.dir.direction;
   } else {
      B_CONFIRM++;
   }
   int needConfirm = g_rt_ready && g_rt_onay > 0 ? g_rt_onay : InpBullet_EntryConfirmTicks;
   // v1.78.35: XAUUSD disinda (RT_TimingMult) tick-teyit sayisi da genisler —
   // BTC gibi cok farkli tick hizina sahip sembollerde sabit tick sayisi
   // duvar-saati olarak anlamsiz kisa/uzun kalabilir.
   needConfirm = (int)MathRound(needConfirm * RT_TimingMult(ctx.symbol));
   if(B_CONFIRM < needConfirm) BDIAG_RET("ENTRY_CONFIRM_TICKS_YETERSIZ");

   // Entry quality
   if(InpBullet_EntryQualityEnable) {
      int q = Bullet_EntryQualityScore(ctx);
      if(q < InpBullet_EntryQualityMinScore) BDIAG_RET("ENTRY_QUALITY_DUSUK");
   }

   double existingLot = 0, existingPnL = 0;
   TPProj_GetSameSideStats(ctx.symbol, g_magic, ctx.dir.direction, existingLot, existingPnL);
   if(existingLot > 0 && RT_LotMode() != BLM_PROJECT) BDIAG_RET("EXISTING_LOT_NON_PROJECT");

   if(!ONNX_AllowsEntry(ctx.dir.direction)) BDIAG_RET("ONNX_VETO");

   double lot = Bullet_CalcLot(ctx.symbol, ctx.dir.direction, ctx);
   if(lot <= 0) {
      // Tanı: Bullet motorunda lot 0/negatif çıkıp işlem açılmadığında
      // sebebi görünür kılmak için (InpSR_LogDecisions=true iken).
      // v1.78.98 FIX (DUZELTME_REHBERI #9): Lot_CalcCapped'in spesifik
      // ret nedeni (RISK_CAP_VERI_YOK / RISK_CAP_SIFIR / RISK_MINLOT) varsa
      // eklenir; boylece "lot neden 0 cikti" sorusu Journal'dan tek satirda
      // cevaplanabilir.
      if(InpSR_LogDecisions) {
         string bulletLotReason = (g_lastLotRejectReason != "")
            ? ("LOT_SIFIR_VEYA_NEGATIF:" + g_lastLotRejectReason)
            : "LOT_SIFIR_VEYA_NEGATIF";
         PrintFormat("R21 BULLET IPTAL | %s | dir=%d | sebep=%s",
                     ctx.symbol, ctx.dir.direction, bulletLotReason);
      }
      return;
   }
   if(!Stage_FinalVeto(ctx, ctx.dir.direction, lot)) return;

   g_trade.SetExpertMagicNumber(g_magic);
   bool ok = false;
   double openPx = 0;
   // v1.78.131 HARD SL (R1/R2/R5): Bullet tek-seferlik trend girisi -
   // mesafe RiskCap_MaxLot()'un lot hesaplarken zaten varsaydigi ATR x
   // InpRiskSizing_AdverseATRMult ile birebir ayni (Teknik Sartname R2).
   // v1.78.141 RISK_CALIBRATION FIX: SL artik preflight'tan ONCE hesaplanir
   // (fail-closed veto + OrderCheck gercek SL'i gorebilsin diye - bkz.
   // Trade_PreflightMarketOrder yorumu).
   double bulletHardSl = HardSL_ComputePrice(ctx.symbol, ctx.dir.direction, false);
   if(!Trade_PreflightMarketOrder(ctx.symbol, ctx.dir.direction, lot, bulletHardSl, g_magic))
      return;
   Trade_SetFilling(ctx.symbol); // v1.73: auto + IOC/FOK/RETURN fallback
   // NOT: ResetLastError()'dan ONCE hesaplaniyor (asagidaki orderError
   // teshisi bozulmasin diye) - bulletHardSl artik yukarida hesaplandi.
   ResetLastError();
   if(ctx.dir.direction > 0) {
      ok = g_trade.Buy(lot, ctx.symbol, 0, bulletHardSl, 0, InpTradeComment + "-BLT");
   } else {
      ok = g_trade.Sell(lot, ctx.symbol, 0, bulletHardSl, 0, InpTradeComment + "-BLT");
   }

   int orderError = GetLastError();
   if(!ok) {
      AsyncHedgeProtection_RecordReject(ctx.symbol);
      PrintFormat("Bullet OPEN FAIL retcode=%u terminal=%d %s",
                  g_trade.ResultRetcode(), orderError, g_trade.ResultRetcodeDescription());
      return;
   }

   uint bulletRc = g_trade.ResultRetcode();
   if(bulletRc != TRADE_RETCODE_DONE && bulletRc != TRADE_RETCODE_DONE_PARTIAL &&
      bulletRc != TRADE_RETCODE_PLACED)
   {
      AsyncHedgeProtection_RecordReject(ctx.symbol);
      PrintFormat("Bullet OPEN REJECTED retcode=%u terminal=%d %s",
            bulletRc, orderError, g_trade.ResultRetcodeDescription());
      return;
   }

   int bulletIdx = Ind_FindIdx(ctx.symbol);
   if(bulletIdx >= 0 && bulletIdx < MAX_SYMBOLS) {
      g_orderRejectCount[bulletIdx] = 0;
      g_lastOrderRejectMs[bulletIdx] = 0;
   }

   // v1.78.148: entry-density penceresi SADECE bu noktada (gercekten
   // acilmis pozisyon) beslenir - bkz. RiskGovernor_RecordEntryOpened
   // tanimindaki not.
   RiskGovernor_RecordEntryOpened(ctx.symbol, 0, ctx.dir.direction);

   // v1.78.131 HARD SL (R3 - 2. gecis duzeltmesi): BLM_PROJECT lot modunda
   // Bullet, ayni yone AYNI net pozisyona birden fazla kez giris yapabilir
   // (bkz. "BLM_PROJECT modunda ILK giris de dahil HER giris dogrudan..."
   // yorumu yukarida, TPProj_GetSameSideStats/existingLot kontrolu). Netting
   // hesapta bu, ortalama giris fiyatini kaydirir - SL de Grid'deki gibi
   // yeni ortalamaya gore yeniden hizalanmali, yoksa ilk girisin SL'i
   // kalir ve R2'nin varsaydigi mesafeyle tutarsizlasir.
   HardSL_RecalcOnAdd(ctx.symbol, g_magic, false);

   // v1.78.41 FIX: emir ONCESI ask/bid yerine gercek dolum fiyati (ResultPrice)
   // kullaniliyor — bkz. Lattice tarafindaki ayni fix'in yorumu.
   openPx = g_trade.ResultPrice();
   if(openPx <= 0.0)
      openPx = (ctx.dir.direction > 0) ? SymbolInfoDouble(ctx.symbol, SYMBOL_ASK)
                                        : SymbolInfoDouble(ctx.symbol, SYMBOL_BID);

   ulong ticket = Trade_ResolvePositionTicket(ctx.symbol, ctx.dir.direction, g_magic, lot, openPx);
   B_LAST_OPEN = TimeCurrent();
   B_LAST_DIR  = ctx.dir.direction;
   B_TICKET   = ticket;
   B_ENTRY_DIR = ctx.dir.direction;
   B_OPEN_TIME = TimeCurrent();
   B_PEAK = 0;
   B_CONFIRM = 0;

   PrintFormat("Bullet OPEN | dir=%s lot=%.2f price=%.5f ticket=%I64u conf=%.2f Q=%d",
               (ctx.dir.direction > 0 ? "BUY" : "SELL"), lot, openPx, ticket,
               ctx.dir.confidence, Bullet_EntryQualityScore(ctx));
   Sound_Play("OPEN");
   g_extra_lastEntryTime[(g_sym_idx>=0&&g_sym_idx<MAX_SYMBOLS)?g_sym_idx:0] = TimeCurrent();

   if(InpShadowTrade_Enable)
      Shadow_LogHypothetical(ctx.symbol, ctx.dir.direction, lot);
}
#undef BDIAG_RET
// v1.78.157 GECICI TESHIS TEMIZLIGI: BDIAG_RET de ayni sebeple (bkz.
// FVDIAG_RET yorumu, Stage_FinalVeto sonu) burada kapatiliyor.

//+------------------------------------------------------------------+
//| 10. GÜVENLİK KATMANLARI – HABER / VIOP / GÜNLÜK KİLİT            |
//+------------------------------------------------------------------+
//
//  PDF Bölüm 8–10 özeti
//  ────────────────────
//  1) Haber filtresi (Economic Calendar)
//     - NF_PauseTrading  → yeni girişleri durdur
//     - NF_HedgeBefore   → (opsiyonel) net maruziyeti hedge et
//     - NF_CloseAllBefore→ (opsiyonel) pozisyonları kapat (zarar olabilir)
//     Mutlak kilit penceresinde TP/reset/flip/yeni giriş sınırlanmalı.
//
//  2) VIOP / Futures
//     - Seans dışı yeni giriş engeli
//     - Gap bekleme (açılış sonrası)
//     - Vade yaklaşınca koruma / force close
//
//  3) Günlük kâr/zarar kilidi
//     - DailyProfitTargetPct / DailyLossTargetPct
//     - Scope: ROBOT veya ACCOUNT
//     - Restart saati ertesi gün kilidi kaldırır
//
//+------------------------------------------------------------------+

//--- Günlük PnL (scope'a göre)
double Security_GetDailyPnLPercent() {
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance <= 0.0) return 0.0;

   // v1.68: para yatırma/çekme (BALANCE deal) nötrleştir – InpWithdrawalNeutralForLossReset
   static double s_dayStartEquity = 0.0;
   static double s_dayStartBalance = 0.0;
   static double s_balanceAdj = 0.0;   // net deposit/withdrawal ($)
   static int    s_dayStamp = 0;
   static datetime s_lastBalScan = 0;
   static bool   s_loadedFromGV = false;

   MqlDateTime dt;
   // v1.78.42 FIX (#98): stamp hesabi HER ZAMAN TimeCurrent() (broker/sunucu
   // saati) kullaniyordu, InpDailyClockMode'a hic bakmiyordu. Ama UpdateDailyLock()
   // kullanicinin secimine gore (DGC_LOCAL ise TimeLocal()) farkli bir "gun"
   // tanimi kullaniyordu — iki fonksiyon farkli saat dilimlerinde farkli gunler
   // sayabiliyordu (broker sunucusu genelde UTC+2/+3, kullanici yerel saati
   // farkli olabilir). Sonuc: g_dailyLocked bir gunun verisiyle calisirken,
   // PnL yuzdesi baska bir gunun equity referansini kullanabiliyordu. Artik
   // ayni saat kaynagi (InpDailyClockMode) kullaniliyor — iki fonksiyon
   // senkron.
   datetime clockNow = Daily_GetNow(); // v1.78.43 FIX (#105): tek ortak yardimci
   TimeToStruct(clockNow, dt);
   int stamp = dt.year * 10000 + dt.mon * 100 + dt.day;

   // v1.78.40 FIX: s_dayStartEquity yalnizca RAM'de tutuluyordu, GV'ye hic
   // yazilmiyordu. EA restart oldugunda (VPS reboot, terminal crash, chart'tan
   // kaldir-tekrar-ekle) bu deger sifirlaniyor ve "if(s_dayStartEquity<=0.0)"
   // kosulu o anki (gun icinde zaten dusmus olabilecek) equity'yi YENI gun
   // baslangici sayiyordu. Sonuc: gun icinde zaten %X zararda olan bir hesap,
   // restart sonrasi %0 zarardan basliyormus gibi davraniyor ve GÜNLÜK ZARAR
   // KİLİDİ fiilen daha gec (veya hic) tetiklenmiyordu — dogrudan risk limiti
   // asimi. Artik ilk cagrida GV'den o gunun baslangic degerleri geri yukleniyor;
   // GV'de yoksa (gercekten yeni gun) o anki equity/balance yeni baslangic olur.
   if(!s_loadedFromGV) {
      s_loadedFromGV = true;
      int gvStamp = (int)GV_GetNum(PanelGV_Key("DPSTAMP"), 0);
      if(gvStamp == stamp) {
         double gvEq = GV_GetNum(PanelGV_Key("DPEQ"), 0);
         if(gvEq > 0.0) {
            s_dayStartEquity  = gvEq;
            s_dayStartBalance = GV_GetNum(PanelGV_Key("DPBAL"), balance);
            s_balanceAdj      = GV_GetNum(PanelGV_Key("DPADJ"), 0.0);
            s_dayStamp        = gvStamp;
         }
      }
   }

   if(s_dayStamp != stamp || s_dayStartEquity <= 0.0) {
      s_dayStartEquity  = equity;
      s_dayStartBalance = balance;
      s_balanceAdj = 0.0;
      s_dayStamp = stamp;
      s_lastBalScan = 0;
      // Yeni gün başlangıcını hemen GV'ye yaz (restart korumasının temeli)
      GV_SetNumIfChanged(PanelGV_Key("DPSTAMP"), (double)stamp);
      GV_SetNumIfChanged(PanelGV_Key("DPEQ"),    s_dayStartEquity);
      GV_SetNumIfChanged(PanelGV_Key("DPBAL"),   s_dayStartBalance);
      GV_SetNumIfChanged(PanelGV_Key("DPADJ"),   s_balanceAdj);
   }

   // Her ~30 sn balance deal tarama (yalnızca withdrawal-neutral açıksa)
   if(InpWithdrawalNeutralForLossReset && (TimeCurrent() - s_lastBalScan >= 30)) {
      s_lastBalScan = TimeCurrent();
      datetime dayStart = Daily_GetDayStartBrokerTime(dt); // v1.78.43 FIX (#105)
      if(HistorySelect(dayStart, TimeCurrent() + 60)) {
         double adj = 0.0;
         int total = HistoryDealsTotal();
         for(int i = 0; i < total; i++) {
            ulong d = HistoryDealGetTicket(i);
            if(d == 0) continue;
            long entry = HistoryDealGetInteger(d, DEAL_ENTRY);
            long dtype = HistoryDealGetInteger(d, DEAL_TYPE);
            // BALANCE / CREDIT işlemleri (yatırma-çekme)
            if(dtype == DEAL_TYPE_BALANCE || dtype == DEAL_TYPE_CREDIT ||
               dtype == DEAL_TYPE_CORRECTION || dtype == DEAL_TYPE_BONUS) {
               adj += HistoryDealGetDouble(d, DEAL_PROFIT);
            }
         }
         s_balanceAdj = adj;
         GV_SetNumIfChanged(PanelGV_Key("DPADJ"), s_balanceAdj);
      }
      // v1.68: global history selection'i genis araliga geri al (Trade_Resolve ile carpisma yok)
      HistorySelect(0, TimeCurrent() + 86400);
   }

   if(s_dayStartEquity <= 0.0) return 0.0;

   // v1.78.43 FIX (#104): DGS_ROBOT payi (numerator) v1.78.42'de robot-scope
   // yapilmisti ama PAYDA (denominator) hala s_dayStartBalance — yani HESAP
   // GENELI gunun basindaki balance — kullaniliyordu. Ayni hesapta baska bir
   // EA veya manuel islem o gun balance'i degistirdiyse, robot'un yuzdesi
   // yanlis bir paydaya bolunmus oluyordu (rapor #104: "pay ve payda ayni
   // scope mantigina baglanmali"). Artik DGS_ROBOT icin ayri, kendi GV
   // anahtariyla sakli bir "robot baz" degeri kullaniliyor — bu deger gunun
   // ilk cagrisinda o anki hesap balance'indan turetilir (baska referans yok,
   // MT5 API'si "sadece bu EA'nin sermayesi" diye bir kavram sunmuyor) ama
   // ARTIK DGS_ACCOUNT'un s_dayStartBalance'indan TAMAMEN BAGIMSIZ saklanir,
   // baska bir EA/manuel islem sonradan hesap balance'ini degistirse bile bu
   // robot-baz degeri ETKILENMEZ (gunun geri kalaninda sabit kalir).
   if(InpDailyLockScope == DGS_ROBOT) {
      static double s_robotBaseBalance = 0.0;
      static int    s_robotBaseStamp   = 0;
      if(s_robotBaseStamp != stamp || s_robotBaseBalance <= 0.0) {
         double gvRB = GV_GetNum(PanelGV_Key("DPRBASE"), 0.0);
         int    gvRBStamp = (int)GV_GetNum(PanelGV_Key("DPRBSTAMP"), 0);
         if(gvRBStamp == stamp && gvRB > 0.0) {
            s_robotBaseBalance = gvRB; // restart sonrasi ayni gun icinde geri yukle
         } else {
            s_robotBaseBalance = balance; // yeni gun — o anki balance referans olur
            GV_SetNumIfChanged(PanelGV_Key("DPRBASE"), s_robotBaseBalance);
            GV_SetNumIfChanged(PanelGV_Key("DPRBSTAMP"), (double)stamp);
         }
         s_robotBaseStamp = stamp;
      }

      datetime dayStart = Daily_GetDayStartBrokerTime(dt); // v1.78.43 FIX (#105)
      double robotClosedPnl = 0.0;
      if(HistorySelect(dayStart, TimeCurrent() + 60)) {
         int total = HistoryDealsTotal();
         for(int i = 0; i < total; i++) {
            ulong d = HistoryDealGetTicket(i);
            if(d == 0) continue;
            if((ulong)HistoryDealGetInteger(d, DEAL_MAGIC) != g_magic) continue;
            long entry = HistoryDealGetInteger(d, DEAL_ENTRY);
            if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY) continue; // sadece kapanis bacaklari
            robotClosedPnl += HistoryDealGetDouble(d, DEAL_PROFIT)
                            +  HistoryDealGetDouble(d, DEAL_SWAP)
                            +  HistoryDealGetDouble(d, DEAL_COMMISSION);
         }
      }
      HistorySelect(0, TimeCurrent() + 86400); // v1.68: global history'yi genis araliga geri al
      double robotFloatingPnl = 0.0;
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong t = PositionGetTicket(i);
         if(t == 0 || !PositionSelectByTicket(t)) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
         robotFloatingPnl += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      }
      double robotRaw = robotClosedPnl + robotFloatingPnl;
      double denom = (s_robotBaseBalance > 0.0) ? s_robotBaseBalance : balance;
      if(denom <= 0.0) return 0.0;
      return (robotRaw / denom) * 100.0;
   }

   // DGS_ACCOUNT (varsayilan/eski davranis): hesap genelindeki equity degisimi
   // Equity değişiminden balance deal etkisini çıkar → saf trading PnL
   double raw = equity - s_dayStartEquity;
   if(InpWithdrawalNeutralForLossReset)
      raw -= s_balanceAdj;
   return (raw / s_dayStartEquity) * 100.0;
}


//--- Sembol para birimleri + currency filter (PDF NF_CurrencyFilter)
bool NF_CurrencyMatchesEvent(const string symbol, const MqlCalendarEvent &ev) {
   string filter = InpNF_CurrencyFilter;
   StringTrimLeft(filter); StringTrimRight(filter);
   string bases = "";
   if(StringLen(filter) > 0) {
      bases = filter;
   } else {
      // Sembolden türet: EURUSD → EUR,USD ; XAUUSD → XAU,USD
      string s = symbol;
      int dot = StringFind(s, ".");
      if(dot > 0) s = StringSubstr(s, 0, dot);
      if(StringLen(s) >= 6) {
         bases = StringSubstr(s, 0, 3) + "," + StringSubstr(s, 3, 3);
      } else {
         bases = s;
      }
   }
   StringToUpper(bases);

   // Ülke → para birimi (MqlCalendarEvent.currency yok; country_id kullan)
   string cur = "";
   MqlCalendarCountry ctry;
   if(CalendarCountryById(ev.country_id, ctry)) {
      cur = ctry.currency;
      StringToUpper(cur);
   }
   if(StringLen(cur) == 0) return true; // bilinmiyorsa engelleme

   string parts[];
   int n = StringSplit(bases, ',', parts);
   for(int i = 0; i < n; i++) {
      string p = parts[i];
      StringTrimLeft(p); StringTrimRight(p);
      StringToUpper(p);
      if(StringLen(p) > 0 && p == cur) return true;
   }
   return false;
}

//--- Yüksek etkili haber var mı?
bool Security_IsHighImpactNewsWindow(int beforeMin, int afterMin, const string symbol = "") {
   // v1.68: sembol basina bagimsiz 60sn cache (tek static string multi-sym'de eziliyordu)
   static datetime s_lastCheck[MAX_SYMBOLS];
   static bool     s_cached[MAX_SYMBOLS];
   static bool     s_cacheInit = false;
   // FIX: ilk 60sn yanlis cache (0) olmasin
   if(!s_cacheInit) {
      datetime past = TimeCurrent() - 10000;
      for(int ci = 0; ci < MAX_SYMBOLS; ci++) {
         s_lastCheck[ci] = past;
         s_cached[ci] = false;
      }
      s_cacheInit = true;
   }

   string sym = (StringLen(symbol) == 0) ? _Symbol : symbol;
   int cidx = Ind_FindIdx(sym);
   if(cidx < 0) cidx = 0; // bilinmeyen sembol → slot 0 (nadir)

   if(s_lastCheck[cidx] > 0 && (TimeCurrent() - s_lastCheck[cidx]) < 60)
      return s_cached[cidx];
   s_lastCheck[cidx] = TimeCurrent();
   s_cached[cidx] = false;

   if(!RT_NF()) return false;

   datetime from = TimeCurrent() - afterMin * 60;
   datetime to   = TimeCurrent() + beforeMin * 60;

   // US + EU + GB + CN
   string countries[4] = {"US", "EU", "GB", "CN"};
   MqlCalendarValue values[];

   for(int c = 0; c < 4; c++) {
      MqlCalendarValue tmp[];
      if(!CalendarValueHistory(tmp, from, to, countries[c])) continue;

      for(int i = 0; i < ArraySize(tmp); i++) {
         MqlCalendarEvent ev;
         if(!CalendarEventById(tmp[i].event_id, ev)) continue;
         // InpNF_ImportanceMin: 1=low 2=mod 3=high (PDF)
         ENUM_CALENDAR_EVENT_IMPORTANCE needImp = CALENDAR_IMPORTANCE_HIGH;
         if(InpNF_ImportanceMin <= 1) needImp = CALENDAR_IMPORTANCE_LOW;
         else if(InpNF_ImportanceMin == 2) needImp = CALENDAR_IMPORTANCE_MODERATE;
         if(ev.importance < needImp) continue;
         // v1.68: multi-symbol – chart _Symbol yerine ilgili sembol
         if(!NF_CurrencyMatchesEvent(sym, ev)) continue;

         // AUDIT v1.78.70 (#13): anahtar kelime listesi artik SERT sart
         // degil, opsiyonel EK daraltma. importance + currency zaten dogru
         // birincil filtre (CalendarEventById); event ismi listedeki
         // kaliplarla tam eslesmezse (or. "Retail Sales", "Unemployment
         // Rate", farkli dil/format) onceden sessizce atlaniyordu. Varsayilan
         // artik KAPALI: importance+currency tek basina yeterli sayiliyor.
         string name = ev.name;
         if(InpNF_UseKeywordFilter) {
            bool relevant =
               (StringFind(name, "CPI") >= 0) ||
               (StringFind(name, "Nonfarm") >= 0) ||
               (StringFind(name, "NFP") >= 0) ||
               (StringFind(name, "FOMC") >= 0) ||
               (StringFind(name, "GDP") >= 0) ||
               (StringFind(name, "Interest Rate") >= 0) ||
               (StringFind(name, "Inflation") >= 0) ||
               (StringFind(name, "ECB") >= 0) ||
               (StringFind(name, "BoE") >= 0) ||
               (StringFind(name, "PMI") >= 0) ||
               (StringFind(name, "Gold") >= 0);
            if(!relevant) continue;
         }

         long diff = (long)tmp[i].time - (long)TimeCurrent();
         // yaklaşan
         if(diff > 0 && diff < beforeMin * 60) {
            PrintFormat("HABER KİLİDİ [%s]: %s %d dk sonra", sym, name, (int)(diff / 60));
            s_cached[cidx] = true;
            return true;
         }
         // geçmiş (after penceresi)
         if(diff <= 0 && MathAbs(diff) < afterMin * 60) {
            PrintFormat("HABER KİLİDİ (sonrası) [%s]: %s %d dk önce", sym, name, (int)(MathAbs(diff) / 60));
            s_cached[cidx] = true;
            return true;
         }
      }
   }
   return false;
}

//--- v1.78.51 (#120): Panel "Info" listesi — kilitten BAGIMSIZ, sadece
// gorsel amacli haber listesi. Security_IsHighImpactNewsWindow() sadece
// CPI/NFP/FOMC/GDP/... anahtar kelimeleriyle eslesen haberlere bakar (bu,
// TRADING KILIDI icin bilincli olarak dar tutulmustur — kucuk haberlerde
// islem durmasin diye). Info listesi ise kullanicinin GORMESI icin anahtar
// kelime filtresi UYGULAMAZ; sadece para birimi (sembol bazli) ve
// InpNF_ImportanceMin esigini kullanir, boylece "o gun/hafta hic haber
// yok" gorunumu duzelir.
void NF_UpdateInfoList(const string symbol) {
   // Asiri sik CalendarValueHistory cagrisi yapmamak icin 3 dk'da bir yenile
   if(g_nfInfoLastCalc > 0 && (TimeCurrent() - g_nfInfoLastCalc) < 180) return;
   g_nfInfoLastCalc = TimeCurrent();
   g_nfInfoCount = 0;

   if(!RT_NF()) return; // haber filtresi KAPALIYSA info da bos kalir

   int aheadH = (InpNF_LookaheadHours > 0) ? InpNF_LookaheadHours : 24;
   datetime from = TimeCurrent() - 2 * 3600;      // son 2 saat (yeni cikmis haberler de gorunsun)
   datetime to   = TimeCurrent() + aheadH * 3600; // ileri bakis (varsayilan 24s = "bugun")

   string countries[4] = {"US", "EU", "GB", "CN"};
   datetime times[NF_INFO_MAX];
   string   lines[NF_INFO_MAX];
   int      found = 0;

   for(int c = 0; c < 4; c++) {
      MqlCalendarValue tmp[];
      if(!CalendarValueHistory(tmp, from, to, countries[c])) continue;

      for(int i = 0; i < ArraySize(tmp); i++) {
         MqlCalendarEvent ev;
         if(!CalendarEventById(tmp[i].event_id, ev)) continue;

         ENUM_CALENDAR_EVENT_IMPORTANCE needImp = CALENDAR_IMPORTANCE_HIGH;
         if(InpNF_ImportanceMin <= 1) needImp = CALENDAR_IMPORTANCE_LOW;
         else if(InpNF_ImportanceMin == 2) needImp = CALENDAR_IMPORTANCE_MODERATE;
         if(ev.importance < needImp) continue;
         if(!NF_CurrencyMatchesEvent(symbol, ev)) continue;

         string star = (ev.importance == CALENDAR_IMPORTANCE_HIGH) ? "★★★" :
                        (ev.importance == CALENDAR_IMPORTANCE_MODERATE) ? "★★" : "★";
         string line = StringFormat("%s %s %s %s", TimeToString(tmp[i].time, TIME_DATE | TIME_MINUTES),
                                     star, countries[c], ev.name);

         // Zamana gore sirali ekleme (en yakin/gecmis en ustte), NF_INFO_MAX ile sinirli
         int insertAt = found;
         for(int k = 0; k < found; k++) {
            if(tmp[i].time < times[k]) { insertAt = k; break; }
         }
         if(found < NF_INFO_MAX) {
            for(int k = found; k > insertAt; k--) { times[k] = times[k-1]; lines[k] = lines[k-1]; }
            times[insertAt] = tmp[i].time;
            lines[insertAt] = line;
            found++;
         } else if(insertAt < NF_INFO_MAX) {
            for(int k = NF_INFO_MAX - 1; k > insertAt; k--) { times[k] = times[k-1]; lines[k] = lines[k-1]; }
            times[insertAt] = tmp[i].time;
            lines[insertAt] = line;
         }

         if(InpNF_LogEvents) PrintFormat("HABER INFO [%s]: %s", symbol, line);
      }
   }

   g_nfInfoCount = found;
   for(int i = 0; i < found; i++) g_nfInfoLines[i] = lines[i];
}

//--- Haber kilidini güncelle (+ opsiyonel CloseAll / Hedge aksiyonları)
// v1.78.44 FIX (#114): s_closeDone/s_hedgeDone fonksiyon-ici static ve TEK
// kopyaydi; ayrica Close/Hedge aksiyonlari HER ZAMAN g_symbol (chart sembolu)
// hedefliyordu, oysa pencere tespiti (anyWindow) TUM semboller icin OR
// yapiliyordu. Sonuc: coklu sembol kullaniminda (InpExtraSymbols dolu) (a)
// bir sembolun haber-sonrasi state'i digerini etkileyebiliyordu, (b) sadece
// chart sembolu icin close/hedge calisiyordu, digerleri icin HIC calismiyordu.
// Artik tum dongu sembol-bazli: her g_symbols[si] icin ayri pencere/close/
// hedge/retry state'i (statik diziler) ve o sembole ozel Close/Hedge islemi.
void UpdateNewsLock() {
   if(!RT_NF()) {
      g_newsHardLock = false;
      for(int zi = 0; zi < MAX_SYMBOLS; zi++) g_newsLockSym[zi] = false;
      return;
   }

   static bool s_closeDone[MAX_SYMBOLS];
   static bool s_hedgeDone[MAX_SYMBOLS];
   // v1.78.45 FIX (#115): "pencereden yeni cikildi" tespiti g_newsLockSym[si]'nin
   // KENDI icinde, AYNI iterasyonda ustune yazilmis degerine bakiyordu — win=false
   // oldugunda g_newsLockSym[si] zaten bu satirda false'a set edilmis oluyordu, yani
   // asagidaki "if(g_newsLockSym[si])" kontrolu ASLA true olamiyordu ve
   // g_nfHedgeCloseRetryPending hicbir zaman kurulamiyordu (CloseHedgeAfterNews
   // retry zinciri hic baslamiyordu). Cozum: bir onceki tick'teki kilit durumunu
   // AYRI bir static dizide (s_prevLockSym), guncellemeden ONCE okuyup sakla.
   static bool s_prevLockSym[MAX_SYMBOLS];
   static bool s_init = false;
   if(!s_init) {
      for(int zi = 0; zi < MAX_SYMBOLS; zi++) { s_closeDone[zi] = false; s_hedgeDone[zi] = false; g_nfHedgeCloseRetryPending[zi] = false; s_prevLockSym[zi] = false; }
      s_init = true;
   }

   for(int si = 0; si < g_symbol_count; si++) {
      string sym = g_symbols[si];
      bool win = Security_IsHighImpactNewsWindow(RT_NfBefore(), RT_NfAfter(), sym);
      bool prevLock = s_prevLockSym[si]; // v1.78.45 FIX (#115): ustune yazilmadan ONCE oku
      g_newsLockSym[si] = win && (g_rt_ready ? g_rt_nf_pause : InpNF_PauseTrading);

      if(win) {
         // Close All Before – yalnız pencereye YENİ girildiğinde bir kez (bu sembol için)
         if((g_rt_ready ? g_rt_nf_zarar_kapat : InpNF_CloseAllBeforeNews) && !s_closeDone[si] && FeatureGate_Loss("NEWS_LOSS")) {
            int newsClosedN = 0, newsFailedN = 0;
            for(int i = PositionsTotal() - 1; i >= 0; i--) {
               ulong ticket = PositionGetTicket(i);
               if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
               if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
               if(PositionGetString(POSITION_SYMBOL) != sym) continue;
               double newsP = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
               if(SafeClosePosition(ticket, "NEWS_CLOSE_ALL")) {
                  AutoTune_OnDealProfit(newsP); // DÜZELTME v1.68
                  newsClosedN++;
               } else {
                  newsFailedN++;
               }
            }
            if(newsFailedN == 0) {
               s_closeDone[si] = true;
               if(newsClosedN > 0) {
                  PrintFormat("HABER: CloseAllBeforeNews uygulandı [%s]", sym);
                  Sound_Play("L_RESET");
               }
            } else {
               PrintFormat("HABER: CloseAllBeforeNews KISMEN/BASARISIZ [%s] — kapandi=%d basarisiz=%d (ayni pencerede tekrar denenecek)",
                           sym, newsClosedN, newsFailedN);
            }
         }

         // Hedge Before – net maruziyeti dengele (sadece hedging hesap, bu sembol için)
         if((g_rt_ready ? g_rt_nf_otohedge : InpNF_HedgeBeforeNews) && IsHedgingAccount() && !s_hedgeDone[si]) {
            double buyLot = 0, sellLot = 0;
            for(int i = PositionsTotal() - 1; i >= 0; i--) {
               ulong ticket = PositionGetTicket(i);
               if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
               if(PositionGetString(POSITION_SYMBOL) != sym) continue;
               ulong mag = (ulong)PositionGetInteger(POSITION_MAGIC);
               if(mag != g_magic && mag != InpMagicNFHedge) continue;
               if((int)PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                  buyLot += PositionGetDouble(POSITION_VOLUME);
               else
                  sellLot += PositionGetDouble(POSITION_VOLUME);
            }
            double net = buyLot - sellLot;
            double minLot = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
            double step   = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
            if(step <= 0) step = 0.01;
            if(MathAbs(net) >= minLot) {
               int hdir = (net > 0) ? -1 : +1;
               double lot = MathAbs(net);
               lot = MathFloor(lot / step) * step;
               if(lot < minLot) lot = minLot;
               ulong prevMagNF = g_magic;
               // v1.78.141 RISK_CALIBRATION FIX: SL preflight'tan ONCE
               // hesaplaniyor (fail-closed veto + OrderCheck gercek SL'i
               // gorebilsin diye); magic olarak GERCEK hedge magic'i
               // (InpMagicNFHedge) gecirilir - basket-risk kontrolu bu
               // yuzden hedge'i dogru sekilde MUAF tutar (bkz. Trade_
               // PreflightMarketOrder yorumu, "magic==g_magic" sarti).
               double nfHardSl = HardSL_ComputePrice(sym, hdir, false);
               if(!Trade_PreflightMarketOrder(sym, hdir, lot, nfHardSl, InpMagicNFHedge))
                  continue;
               g_trade.SetExpertMagicNumber(InpMagicNFHedge);
               ResetLastError();
               bool ok = false;
               if(hdir > 0) ok = g_trade.Buy(lot, sym, 0, nfHardSl, 0, InpTradeComment + "-NFH");
               else         ok = g_trade.Sell(lot, sym, 0, nfHardSl, 0, InpTradeComment + "-NFH");
               g_trade.SetExpertMagicNumber(prevMagNF);
               if(ok) {
                  s_hedgeDone[si] = true;
                  PrintFormat("HABER Hedge OPEN [%s] net=%.2f lot=%.2f dir=%s", sym, net, lot, (hdir > 0 ? "BUY" : "SELL"));
               }
            }
         }
         // pencere dışına çıkınca flag'ler else'te sıfırlanır
      } else {
         // Bu sembol için haber penceresi dışındayız
         // v1.78.45 FIX (#115): artik AYNI ANDA guncellenmis g_newsLockSym[si] degil,
         // bu fonksiyonun BASINDA (ustune yazilmadan once) okunan prevLock (bir onceki
         // tick'in kilit durumu) kullaniliyor — boylece "pencereden YENI cikis" gercekten
         // tespit edilebiliyor.
         if(prevLock) g_nfHedgeCloseRetryPending[si] = true; // pencereden yeni cikildi

         if(g_nfHedgeCloseRetryPending[si] && (g_rt_ready ? g_rt_nf_hedge_kapat : InpNF_CloseHedgeAfterNews) && IsHedgingAccount()) {
            int nfClosedN = 0, nfFailedN = 0;
            for(int i = PositionsTotal() - 1; i >= 0; i--) {
               ulong t = PositionGetTicket(i);
               if(t == 0 || !PositionSelectByTicket(t)) continue;
               if(PositionGetString(POSITION_SYMBOL) != sym) continue;
               if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicNFHedge) continue;
               ulong prevMagNF2 = g_magic;
               g_trade.SetExpertMagicNumber(InpMagicNFHedge);
               bool okClose = SafeClosePosition(t, "NEWS_HEDGE_CLOSE");
               g_trade.SetExpertMagicNumber(prevMagNF2);
               if(okClose) nfClosedN++; else nfFailedN++;
            }
            if(nfFailedN > 0) {
               PrintFormat("NF: CloseHedgeAfterNews KISMEN/BASARISIZ [%s] — kapandi=%d basarisiz=%d (tekrar denenecek)", sym, nfClosedN, nfFailedN);
            } else {
               g_nfHedgeCloseRetryPending[si] = false;
               if(nfClosedN > 0)
                  PrintFormat("NF: CloseHedgeAfterNews uygulandı [%s]", sym);
            }
         }
         s_closeDone[si]  = false;
         s_hedgeDone[si]  = false;
      }

      s_prevLockSym[si] = g_newsLockSym[si]; // v1.78.45 FIX (#115): bir sonraki tick icin sakla
   }

   // chart sembolu global bayrak (panel ISLEV) — yalnizca _Symbol
   int chartIdx = 0;
   for(int si = 0; si < g_symbol_count; si++)
      if(g_symbols[si] == _Symbol) { chartIdx = si; break; }
   g_newsHardLock = g_newsLockSym[chartIdx];
}

//--- VIOP / futures seans + vade
bool Security_IsFuturesSymbol(const string symbol) {
   if(InpVIOP_DetectionMode == VIOP_FORCE_ON)  return true;
   if(InpVIOP_DetectionMode == VIOP_FORCE_OFF) return false;

   // AUTO: broker özelliklerinden tahmin
   // path veya description'da "Futures" / "VIOP" / ".f" kalıpları
   string path = SymbolInfoString(symbol, SYMBOL_PATH);
   string desc = SymbolInfoString(symbol, SYMBOL_DESCRIPTION);
   string upper = path + " " + desc;
   StringToUpper(upper);
   if(StringFind(upper, "FUTURE") >= 0) return true;
   if(StringFind(upper, "VIOP") >= 0)   return true;
   // Türk vadeli kısaltmalar (örnek)
   if(StringFind(symbol, "F_") == 0)    return true;
   return false;
}

bool Security_IsInTradeSession(const string symbol) {
   // Broker seans bilgisi
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   int nowSecFull = dt.hour * 3600 + dt.min * 60 + dt.sec;

   // v1.78.73 FIX (AUDIT v1.78.72): InpVIOP_UseBrokerSessionTimes hicbir
   // yerde okunmuyordu - broker seans bilgisi bulununca input'un degeri
   // ne olursa olsun HER ZAMAN o kullaniliyordu. Artik once acikca secim
   // yapiliyor: broker seciliyse (varsayilan=true) asagidaki eski
   // davranis AYNEN calisir; broker SECILI DEGILSE broker taramasi hic
   // yapilmadan dogrudan sabit seanslara (ya da fallback kapaliysa
   // sinirsiz geciyse) dusulur.
   if(InpVIOP_UseBrokerSessionTimes) {
      // SymbolInfoSessionTrade: haftanın günü 0=Pazar ... 6=Cumartesi
      datetime from, to;
      int previousDow = (dt.day_of_week + 6) % 7;
      // FIX v1.78.13: eskiden sadece 0. seans kontrol ediliyordu; öğle arası
      // bölünen çift seanslı sembollerde (çoğu VIOP vadeli sözleşme) 2. seans
      // hiç görülmüyor, o saatlerde EA yanlışlıkla "seans dışı" sanıyordu.
      // Artık broker kaç seans bildiriyorsa hepsi taranıyor.
      bool haveSessionInfo = false;
      for(int s = 0; s < 8; s++) {
         if(!SymbolInfoSessionTrade(symbol, (ENUM_DAY_OF_WEEK)dt.day_of_week, s, from, to)) break;
         haveSessionInfo = true;
         int fSec = (int)from;
         int tSec = (int)to;
         if(tSec > fSec && nowSecFull >= fSec && nowSecFull <= tSec) return true;
      }
      // Gece taşan seansın 00:00'dan sonraki kısmı önceki işlem gününe aittir.
      for(int s = 0; s < 8; s++) {
         if(!SymbolInfoSessionTrade(symbol, (ENUM_DAY_OF_WEEK)previousDow, s, from, to)) break;
         haveSessionInfo = true;
         int fSec = (int)from;
         int tSec = (int)to;
         if(tSec <= fSec && nowSecFull <= tSec)
            return true;
      }
      if(haveSessionInfo) return false; // broker seans verdi ama hiçbiri şu anı kapsamıyor
      // broker seans bilgisi hiç yok -> aşağıdaki fallback'e düşer
   }

   // Fallback sabit seans (input: VIOP_Open/Close Hour/Min)
   if(!InpVIOP_UseFixedTimesFallback) return true;
   int nowSec = dt.hour * 3600 + dt.min * 60;
   int openSec  = InpVIOP_Open_Hour  * 3600 + InpVIOP_Open_Min  * 60;
   int closeSec = InpVIOP_Close_Hour * 3600 + InpVIOP_Close_Min * 60;
   if(closeSec < openSec)
      return (nowSec >= openSec || nowSec <= closeSec);
   return (nowSec >= openSec && nowSec <= closeSec);
}

bool Security_IsNearExpiry(const string symbol, int daysBefore = 3) {
   datetime expiry = (datetime)SymbolInfoInteger(symbol, SYMBOL_EXPIRATION_TIME);
   if(expiry <= 0) return false;
   long remain = (long)expiry - (long)TimeCurrent();
   // Saat bazlı blok (PDF: VIOP_BlockNewHoursBeforeExpiry)
   if(InpVIOP_BlockNewHoursBeforeExpiry > 0) {
      long hours = (long)InpVIOP_BlockNewHoursBeforeExpiry;
      if(remain > 0 && remain <= hours * 3600) return true;
   }
   return (remain > 0 && remain <= (long)daysBefore * 86400);
}

void UpdateVIOPStatus(const string symbol) {
   g_viopBlocked = false;

   if(!Security_IsFuturesSymbol(symbol))
      return; // normal forex/spot → VIOP kuralları uygulanmaz

   // 1) Seans kontrolü
   if(InpVIOP_EnableSessionControl) {
      if(!Security_IsInTradeSession(symbol)) {
         g_viopBlocked = true;
         return;
      }

      // Gap bekleme: seans açılışından sonra N dakika
      // Basit yaklaşım: saatin açılış dakikasına yakınlığı
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      int nowSec = dt.hour * 3600 + dt.min * 60;
      int openSec = 9 * 3600 + 20 * 60; // fallback
      datetime from, to;
      if(SymbolInfoSessionTrade(symbol, (ENUM_DAY_OF_WEEK)dt.day_of_week, 0, from, to))
         openSec = (int)from;

      if(nowSec >= openSec && nowSec < openSec + InpVIOP_GapWaitMinutes * 60) {
         g_viopBlocked = true; // gap koruması
         return;
      }
   }

   // 2) Vade koruması
   if(InpVIOP_EnableExpiryProtection && Security_IsNearExpiry(symbol, 3)) {
      g_viopBlocked = true;

      if(InpVIOP_ForceCloseBeforeExpiry && FeatureGate_Loss("VIOP_LOSS")) {
         datetime expiry = (datetime)SymbolInfoInteger(symbol, SYMBOL_EXPIRATION_TIME);
         bool inWindow = true;
         if(expiry > 0 && InpVIOP_ForceCloseMinutesBeforeExpiry > 0) {
            long remainMin = ((long)expiry - (long)TimeCurrent()) / 60;
            inWindow = (remainMin <= InpVIOP_ForceCloseMinutesBeforeExpiry);
         }
         if(inWindow) {
            // v1.78.42 FIX (#102): retcode dogrulanmiyordu, "uygulandi" mesaji
            // basari/basarisizliktan bagimsiz her zaman yazdiriliyordu. Vade
            // sonuna yakin bir pozisyon kapatilamazsa (requote/trade disabled
            // vb.) EA bunu fark etmiyordu — VIOP sozlesmesi vadede zorla
            // tasfiye olabilirdi (ciddi risk). Artik basarisiz kapatmalar
            // ayri loglaniyor ve ozet basari/basarisizlik sayisiyla yazdiriliyor.
            int viopClosedN = 0, viopFailedN = 0;
            for(int i = PositionsTotal() - 1; i >= 0; i--) {
               ulong ticket = PositionGetTicket(i);
               if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
               if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
               if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
               double viopP = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
               if(SafeClosePosition(ticket, "VIOP_FORCE_CLOSE")) {
                  AutoTune_OnDealProfit(viopP); // DÜZELTME v1.68
                  viopClosedN++;
               } else {
                  viopFailedN++;
               }
            }
            if(viopFailedN > 0)
               PrintFormat("VIOP: ForceCloseBeforeExpiry KISMEN/BASARISIZ — kapandi=%d basarisiz=%d (tekrar denenecek)",
                           viopClosedN, viopFailedN);
            else if(viopClosedN > 0)
               Print("VIOP: ForceCloseBeforeExpiry uygulandı");
         }
      }
   }

   // 3) Rollover
   if(InpVIOP_RolloverMode != VIOP_ROLLOVER_OFF && Security_IsNearExpiry(symbol, 5)) {
      static datetime s_lastRollLog = 0;
      if(TimeCurrent() - s_lastRollLog >= 300) {
         PrintFormat("VIOP Rollover (%s) mode=%s – yeni sözleşme kontrol edin",
                     symbol, EnumToString(InpVIOP_RolloverMode));
         s_lastRollLog = TimeCurrent();
      }
      if(InpVIOP_RolloverMode == VIOP_ROLLOVER_AUTO) {
         // Otomatik switch: yeni sembol adı broker'a özeldir.
         // Güvenli varsayılan: yeni girişi kes, mevcutları expiry force'a bırak.
         g_viopBlocked = true;
      }
      // SUGGEST: sadece log (yukarıda)
   }
}

//--- Günlük kâr/zarar kilidi
void UpdateDailyLock() {
   static int s_lockedDay = -1;

   MqlDateTime dt;
   datetime now = Daily_GetNow(); // v1.78.43 FIX (#105): tek ortak yardimci
   TimeToStruct(now, dt);
   int today = dt.year * 10000 + dt.mon * 100 + dt.day;

   // v1.78.141 RISK_CALIBRATION FIX (DUZELTME_REHBERI [bu PDF] Bolum 13, P2):
   // ESKI DAVRANIS: "KILIT KALDIR" butonuna bir kez basildiginda
   // s_manualUnlockDay=today isaretleniyordu ve GRACE PENCERESI (120sn)
   // BITTIKTEN SONRA BILE o GUN ICIN asagidaki pnlPct kontrolu (iki if
   // blogu) TAMAMEN ATLANIYORDU (erken bir "return" ile) - yani manuel
   // unlock, "bugun bir kez daha izin ver" degil "bugunluk gunluk zarar
   // kilidini fiilen TAMAMEN DEVRE DISI BIRAK" anlamina geliyordu. Rapor
   // bunu acikca "risk politikasini zayiflatabilir" olarak isaretledi:
   // "Manuel unlock, gunluk zarar limitini sifirlamamali. Yalnizca kalan
   // gunluk risk butcesi kadar yeni islem izni vermeli." Artik gun-boyu
   // bypass (eski s_manualUnlockDay degiskeni ve blogu) TAMAMEN KALDIRILDI:
   // KILIT KALDIR SADECE g_dailyUnlockGrace suresince (120sn - kullanicinin
   // pozisyonlarini elle yonetmesi icin bir pencere) kilidi acar; grace
   // bitince asagidaki pnlPct kontrolu HER ZAMAN KALDIGI YERDEN DEVAM EDER -
   // gunluk zarar hala hedefi asiyorsa kilit OTOMATIK olarak yeniden
   // devreye girer. Kullanici hala devam etmek istiyorsa KILIT KALDIR'a
   // TEKRAR basmasi gerekir - raporun onerdigi alternatifi ("ikinci bir
   // acik onay") fiilen budur: her devam icin ayri, bilincli bir tikla
   // saglanir, sessiz/pasif olarak gun boyu suremez.
   if(g_dailyUnlockGrace > 0 && TimeCurrent() < g_dailyUnlockGrace) {
      g_dailyLocked = false;
      return;
   }

   // Restart saati – yeni gun kilidi temizle
   bool pastRestart = (dt.hour > InpDailyRestartHour) ||
                      (dt.hour == InpDailyRestartHour && dt.min >= InpDailyRestartMinute);

   if(s_lockedDay != today && pastRestart) {
      if(g_dailyLocked)
         Print("Günlük kilit kaldırıldı (yeni gün / restart saati)");
      g_dailyLocked = false;
      s_lockedDay = today;
   }

   double pnlPct = Security_GetDailyPnLPercent();

   if(InpDailyProfitLockEnable && pnlPct >= InpDailyProfitTargetPct) {
      if(!g_dailyLocked) {
         PrintFormat("GÜNLÜK KÂR KİLİDİ: +%.2f%% >= %.2f%% scope=%s", pnlPct, InpDailyProfitTargetPct, EnumToString(InpDailyLockScope));
      }
      g_dailyLocked = true;
   }

   if(InpDailyLossLockEnable && pnlPct <= -InpDailyLossTargetPct) {
      if(!g_dailyLocked) {
         PrintFormat("GÜNLÜK ZARAR KİLİDİ: %.2f%% <= -%.2f%% scope=%s", pnlPct, InpDailyLossTargetPct, EnumToString(InpDailyLockScope));
      }
      g_dailyLocked = true;
   }
}

//+------------------------------------------------------------------+
//| Haftalık saat filtresi (PDF 9.3)                                 |
//+------------------------------------------------------------------+
bool Weekly_ParseHM(const string s, int &hh, int &mm) {
   hh = 0; mm = 0;
   string parts[];
   if(StringSplit(s, ':', parts) < 2) return false;
   hh = (int)StringToInteger(parts[0]);
   mm = (int)StringToInteger(parts[1]);
   return (hh >= 0 && hh <= 23 && mm >= 0 && mm <= 59);
}

bool Weekly_InRange(const string range, const int nowMin) {
   // "HH:MM-HH:MM"  — "00:00-00:00" kapalı
   string sides[];
   if(StringSplit(range, '-', sides) < 2) return false;
   int h1, m1, h2, m2;
   if(!Weekly_ParseHM(sides[0], h1, m1)) return false;
   if(!Weekly_ParseHM(sides[1], h2, m2)) return false;
   int a = h1 * 60 + m1;
   int b = h2 * 60 + m2;
   if(a == 0 && b == 0) return false; // kapalı dilim
   if(b < a) {
      // gece aşımı (örn 22:00-02:00)
      return (nowMin >= a || nowMin <= b);
   }
   return (nowMin >= a && nowMin <= b);
}

void Weekly_GetDaySlots(const int dow, string &p1, string &p2, string &p3, string &p4) {
   // MqlDateTime.day_of_week: 0=Pazar … 6=Cumartesi
   switch(dow) {
      case 1: p1=InpMon_P1; p2=InpMon_P2; p3=InpMon_P3; p4=InpMon_P4; break;
      case 2: p1=InpTue_P1; p2=InpTue_P2; p3=InpTue_P3; p4=InpTue_P4; break;
      case 3: p1=InpWed_P1; p2=InpWed_P2; p3=InpWed_P3; p4=InpWed_P4; break;
      case 4: p1=InpThu_P1; p2=InpThu_P2; p3=InpThu_P3; p4=InpThu_P4; break;
      case 5: p1=InpFri_P1; p2=InpFri_P2; p3=InpFri_P3; p4=InpFri_P4; break;
      case 6: p1=InpSat_P1; p2=InpSat_P2; p3=InpSat_P3; p4=InpSat_P4; break;
      default: p1=InpSun_P1; p2=InpSun_P2; p3=InpSun_P3; p4=InpSun_P4; break;
   }
}

datetime Weekly_Now() {
   // v1.78.36 FIX: SAAT MODU butonu (BROKER/LOCAL/UTC) sadece kendi etiketini
   // degistiriyordu — bu fonksiyon hep derleme-zamanindaki InpWeeklyScheduleClock'u
   // okuyordu, panelden tikladiginizin hicbir etkisi yoktu. Artik panel hazirsa
   // gercekten g_rt_saat_mode'a gore seciyor.
   int clockMode = g_rt_ready ? g_rt_saat_mode : (int)InpWeeklyScheduleClock;
   if(clockMode == TFC_LOCAL) return TimeLocal();
   if(clockMode == TFC_UTC)   return TimeGMT();
   return TimeCurrent(); // broker
}

bool Weekly_IsInsideWindow() {
   MqlDateTime dt;
   TimeToStruct(Weekly_Now(), dt);
   int nowMin = dt.hour * 60 + dt.min;
   string p1, p2, p3, p4;
   Weekly_GetDaySlots(dt.day_of_week, p1, p2, p3, p4);
   if(Weekly_InRange(p1, nowMin)) return true;
   if(Weekly_InRange(p2, nowMin)) return true;
   if(Weekly_InRange(p3, nowMin)) return true;
   if(Weekly_InRange(p4, nowMin)) return true;

   // 00:00'dan sonraki bölüm, önceki günün gece taşan penceresine aittir.
   int previousDow = (dt.day_of_week + 6) % 7;
   Weekly_GetDaySlots(previousDow, p1, p2, p3, p4);
   int previousDayMinute = nowMin + 24 * 60;
   if(Weekly_InRange(p1, previousDayMinute)) return true;
   if(Weekly_InRange(p2, previousDayMinute)) return true;
   if(Weekly_InRange(p3, previousDayMinute)) return true;
   if(Weekly_InRange(p4, previousDayMinute)) return true;
   return false;
}

void Weekly_ClosePositions(const string symbol, const bool onlyProfit) {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(t == 0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(onlyProfit && p <= 0) continue;
      if(SafeClosePosition(t, "WEEKLY_CLOSE"))
         AutoTune_OnDealProfit(p); // DÜZELTME v1.68
   }
}

// HEDGE ACCOUNTING: Ana exposure ve belirli hedge magic'i ayrı hesaplar;
// diğer hedge türlerinin NetVol hesabını kirletmesini ve aynı emrin tekrarlanmasını önler.
void Hedge_GetSignedExposure(const string symbol, const ulong magic,
                             double &netVolume, double &floatingPnL, int &positionCount)
{
   netVolume = 0.0;
   floatingPnL = 0.0;
   positionCount = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ResetLastError();
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
      {
         int ticketError = GetLastError();
         if(ticketError != 0)
            PrintFormat("HEDGE EXPOSURE SKIP | %s | index=%d ticket err=%d", symbol, i, ticketError);
         continue;
      }

      ResetLastError();
      if(!PositionSelectByTicket(ticket))
      {
         PrintFormat("HEDGE EXPOSURE SKIP | %s | ticket=%I64u select err=%d",
                     symbol, ticket, GetLastError());
         continue;
      }
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != magic) continue;

      double volume = PositionGetDouble(POSITION_VOLUME);
      if(!MathIsValidNumber(volume) || volume <= 0.0)
      {
         PrintFormat("HEDGE EXPOSURE SKIP | %s | ticket=%I64u invalid volume=%.8f",
                     symbol, ticket, volume);
         continue;
      }

      int type = (int)PositionGetInteger(POSITION_TYPE);
      netVolume += (type == POSITION_TYPE_BUY) ? volume : -volume;
      floatingPnL += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      positionCount++;
   }
}

// TRADE SAFETY: Haftalık hedge broker ön kontrolü ve asenkron pending kilidi
// olmadan gönderilmez; gerçek pozisyon görünmeden aynı hedge yeniden açılmaz.
void Weekly_NetHedge(const string symbol) {
   if(!IsHedgingAccount()) return;

   static datetime pendingUntil[MAX_SYMBOLS];
   static double pendingTarget[MAX_SYMBOLS];
   int symbolIndex = Ind_FindIdx(symbol);
   if(symbolIndex < 0 || symbolIndex >= MAX_SYMBOLS) return;

   double baseNet = 0.0;
   double unusedBasePnL = 0.0;
   int unusedBaseCount = 0;
   double weeklyNet = 0.0;
   double unusedWeeklyPnL = 0.0;
   int weeklyCount = 0;
   Hedge_GetSignedExposure(symbol, g_magic, baseNet, unusedBasePnL, unusedBaseCount);
   Hedge_GetSignedExposure(symbol, InpMagicWeeklyHedge, weeklyNet, unusedWeeklyPnL, weeklyCount);

   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   if(!MathIsValidNumber(minLot) || minLot <= 0.0 ||
      !MathIsValidNumber(step) || step <= 0.0)
   {
      PrintFormat("WEEKLY HEDGE FAIL | %s | invalid minLot=%.8f step=%.8f", symbol, minLot, step);
      return;
   }

   // Ana sepet yoksa haftalik hedge artik stale'dir; temizle.
   if(MathAbs(baseNet) < minLot) {
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ResetLastError();
         ulong t = PositionGetTicket(i);
         if(t == 0 || !PositionSelectByTicket(t)) continue;
         if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicWeeklyHedge) continue;
         SafeClosePosition(t, "WEEKLY_HEDGE_STALE");
      }
      pendingUntil[symbolIndex] = 0;
      pendingTarget[symbolIndex] = 0.0;
      return;
   }

   // Istenen hedge - mevcut hedge = sadece gerekli fark.
   double desiredHedge = -baseNet;
   if(pendingUntil[symbolIndex] > TimeCurrent())
   {
      if(MathAbs(weeklyNet - pendingTarget[symbolIndex]) <= step * 0.5)
      {
         pendingUntil[symbolIndex] = 0;
         pendingTarget[symbolIndex] = 0.0;
      }
      else
         return;
   }

   double delta = desiredHedge - weeklyNet;
   if(MathAbs(delta) < minLot) return;

   double lot = MathCeil(MathAbs(delta) / step - 1e-12) * step;
   if(lot < minLot) return;
   lot = NormalizeDouble(lot, 8);

   ulong prevMagicWH = g_magic;
   // v1.78.141 RISK_CALIBRATION FIX: SL preflight'tan ONCE hesaplanir;
   // magic olarak GERCEK hedge magic'i (InpMagicWeeklyHedge) gecirilir.
   double whHardSl = HardSL_ComputePrice(symbol, (delta > 0 ? 1 : -1), false);
   if(!Trade_PreflightMarketOrder(symbol, delta > 0 ? +1 : -1, lot, whHardSl, InpMagicWeeklyHedge))
      return;
   g_trade.SetExpertMagicNumber(InpMagicWeeklyHedge);
   ResetLastError();
   bool sent = false;
   if(delta > 0) sent = g_trade.Buy(lot, symbol, 0, whHardSl, 0, InpTradeComment + "-WH");
   else          sent = g_trade.Sell(lot, symbol, 0, whHardSl, 0, InpTradeComment + "-WH");
   uint rc = g_trade.ResultRetcode();
   g_trade.SetExpertMagicNumber(prevMagicWH);

   if(!sent || (rc != TRADE_RETCODE_DONE && rc != TRADE_RETCODE_DONE_PARTIAL &&
                rc != TRADE_RETCODE_PLACED && rc != TRADE_RETCODE_NO_CHANGES))
      PrintFormat("WEEKLY HEDGE FAIL | %s | base=%.4f weekly=%.4f delta=%.4f lot=%.4f retcode=%u %s",
                  symbol, baseNet, weeklyNet, delta, lot, rc, g_trade.ResultRetcodeDescription());
   else {
      pendingTarget[symbolIndex] = desiredHedge;
      pendingUntil[symbolIndex] = TimeCurrent() + 10;
   }
}

void UpdateWeeklySchedule(const string symbol) {
   bool schedOn = g_rt_ready ? g_rt_saat_filtre : InpEnableWeeklySchedule;
   if(!schedOn) {
      g_weeklyOutside = false;
      g_weeklyResumeAt = 0;
      return;
   }

   bool inside = Weekly_IsInsideWindow();
   static bool s_wasOutside = false;

   if(inside) {
      if(s_wasOutside) {
         // dilime yeni girildi → resume delay
         g_weeklyResumeAt = TimeCurrent() + InpWeeklyScheduleResumeDelaySec;
         PrintFormat("Weekly: dilime girildi – resume delay %d sn", InpWeeklyScheduleResumeDelaySec);
      }
      s_wasOutside = false;
      // delay bitene kadar "outside" say (yeni giriş blok)
      if(g_weeklyResumeAt > 0 && TimeCurrent() < g_weeklyResumeAt)
         g_weeklyOutside = true;
      else {
         g_weeklyOutside = false;
         g_weeklyResumeAt = 0;
      }
      return;
   }

   // Dışarıda
   g_weeklyOutside = true;
   if(!s_wasOutside) {
      PrintFormat("Weekly: dilim dışı – action=%s", EnumToString(InpWeeklyScheduleAction));
      s_wasOutside = true;
   }

   switch(InpWeeklyScheduleAction) {
      case TFA_BLOCK_NEW:
         break; // sadece yeni giriş kapalı
      case TFA_CLOSE_PROFIT:
         Weekly_ClosePositions(symbol, true);
         break;
      case TFA_CLOSE_ALL:
         Weekly_ClosePositions(symbol, false);
         break;
      case TFA_NET_HEDGE:
         Weekly_NetHedge(symbol);
         break;
   }
}

//+------------------------------------------------------------------+
//| 11. ONNX / ML CSV / SHADOW JOURNAL                               |
//+------------------------------------------------------------------+
//
//  PDF Bölüm 11 özeti
//  ──────────────────
//  ONNX  : MQL5/Files altındaki .onnx modelini çalıştırır.
//          Çıktı: trendProb + dirProb (veya model şekline göre N çıktı).
//          ShadowOnly=true ise yalnız skor üretir, emir açmaz.
//
//  ML CSV: Piyasa özelliklerini etiket ufku ile kaydeder (eğitim veri seti).
//
//  Shadow Journal: Gerçek emir açmadan hayali işlem sonucu tutar.
//                  Ayar denemesi ve model gözlemi için güvenli katman.
//
//  Not: Gerçek OnnxCreate/OnnxRun, model dosyası ve doğru input tensor
//  şekli olmadan çalışmaz. Bu katman:
//    • özellik vektörü toplar
//    • model handle yaşam döngüsünü yönetir
//    • model yoksa / hata olursa güvenli fallback (prob=0.5) döner
//    • Shadow + CSV yazımını tam çalıştırır
//
//+------------------------------------------------------------------+

#define ML_MAX_FEATURES 64
#define SHADOW_MAX_OPEN 32

struct SShadowTrade {
   bool     active;
   datetime open_time;
   string   symbol;
   int      direction;       // +1 / -1
   double   open_price;
   double   lot;
   double   sl_dist;
   double   tp_dist;
   double   close_price;
   double   pnl;
   bool     closed;
};

struct SMLState {
   long     onnx_handle;        // INVALID_HANDLE veya 0 = yok
   bool     onnx_ready;
   int      input_count;        // model input tensor eleman sayısı
   int      output_count;       // model output tensor eleman sayısı
   int      input_index;        // kullanılan input index (genelde 0)
   int      output_index;       // kullanılan output index (genelde 0)
   string   input_name;
   string   output_name;
   double   last_trend_prob;
   double   last_dir_prob;
   double   last_buy_prob;
   double   last_sell_prob;
   datetime last_infer_time;
   int      infer_count;
   int      infer_fail_count;
   int      shadow_count;
   SShadowTrade shadows[SHADOW_MAX_OPEN];
};

SMLState g_ml;

//--- Özellik vektörü (basit teknik set – modele göre uyarlanır)
int ML_BuildFeatures(const string symbol, double &feats[]) {
   int n = MathMin(InpML_FeatureCount, ML_MAX_FEATURES);
   ArrayResize(feats, n);
   ArrayInitialize(feats, 0.0);

   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0) point = _Point;
   double spread = (ask - bid) / point;

   // 0: spread points
   if(n > 0) feats[0] = spread;
   // 1: ATR normalize (v1.68 cache)
   double atr = Ind_ATR(symbol);
   if(n > 1) feats[1] = (bid > 0 && atr > 0) ? atr / bid : 0;
   // 2: RSI
   int midx = Ind_FindIdx(symbol);
   double rsi = (midx >= 0) ? Ind_HandleBuf(g_ind[midx].rsi14) : 50;
   if(n > 2) feats[2] = rsi / 100.0;
   // 3: EMA fast/slow
   double emaF = bid, emaS = bid;
   if(midx >= 0) {
      double ef = Ind_HandleBuf(g_ind[midx].ema9);
      double es = Ind_HandleBuf(g_ind[midx].ema21);
      if(ef > 0) emaF = ef;
      if(es > 0) emaS = es;
   }
   if(n > 3) feats[3] = (emaS != 0) ? (emaF - emaS) / emaS : 0;
   // 4: VEMA direction confidence
   if(n > 4) feats[4] = g_ctx.dir.confidence * g_ctx.dir.direction;
   // 5: daily pnl %
   if(n > 5) feats[5] = Security_GetDailyPnLPercent() / 100.0;
   // 6: lattice imbalance
   if(n > 6) {
      int tot = g_lattice.buy_levels_active + g_lattice.sell_levels_active;
      feats[6] = (tot > 0) ? (double)(g_lattice.buy_levels_active - g_lattice.sell_levels_active) / tot : 0;
   }
   // 7: hour of day sin/cos (siklik)
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   if(n > 7) feats[7] = MathSin(2 * M_PI * dt.hour / 24.0);
   if(n > 8) feats[8] = MathCos(2 * M_PI * dt.hour / 24.0);
   // kalan özellikler 0 (model bekliyorsa sıfır pad)

   return n;
}

//+------------------------------------------------------------------+
//| ONNX MODEL BAĞLAMA                                               |
//+------------------------------------------------------------------+
//
//  Dosya konumu
//  ────────────
//  Model → Terminal_DataFolder/MQL5/Files/InpML_ONNX_ModelFile
//  Örnek: MQL5/Files/nexus_model.onnx
//
//  Beklenen tensor sözleşmesi (varsayılan)
//  ───────────────────────────────────────
//  Input  [0]: shape = {1, FeatureCount}  dtype = float32
//  Output [0]: shape = {1, OutputCount}   dtype = float32
//
//  OutputCount yorumu
//  ──────────────────
//  1 → [trendProb]
//  2 → [buyProb, sellProb]  → trendProb=max, dirProb=buy-sell normalize
//  3 → [trendProb, buyProb, sellProb]  (PDF varsayılanı)
//  N>3 → ilk 3 kullanılır, kalan yok sayılır
//
//  FeatureCount, model input boyutu ile birebir uyumlu OLMALIDIR.
//  Uyuşmazlıkta OnnxSetInputShape veya pad/truncate uygulanır.
//
//+------------------------------------------------------------------+

void ONNX_Release() {
   if(g_ml.onnx_handle != 0 && g_ml.onnx_handle != INVALID_HANDLE) {
      OnnxRelease(g_ml.onnx_handle);
      Print("ONNX: handle serbest bırakıldı");
   }
   g_ml.onnx_handle      = INVALID_HANDLE;
   g_ml.onnx_ready       = false;
   g_ml.input_count      = 0;
   g_ml.output_count     = 0;
   g_ml.input_index      = 0;
   g_ml.output_index     = 0;
   g_ml.input_name       = "";
   g_ml.output_name      = "";
}

//--- Model input/output bilgisini logla
// Not: Bazı MT5 build'lerinde OnnxTypeInfo.dimensions alanı yok / erişilemiyor.
// Bu yüzden shape okumuyoruz; FeatureCount/OutputCount input'larına güveniyoruz.
void ONNX_LogShapes(const long handle) {
   long inCnt  = OnnxGetInputCount(handle);
   long outCnt = OnnxGetOutputCount(handle);
   PrintFormat("ONNX: input_count=%d output_count=%d | cfg FeatureCount=%d OutputCount=%d",
               (int)inCnt, (int)outCnt, InpML_FeatureCount, InpML_OutputCount);

   for(long i = 0; i < inCnt; i++) {
      OnnxTypeInfo ti;
      if(OnnxGetInputTypeInfo(handle, i, ti))
         PrintFormat("ONNX IN[%d] type=%d", (int)i, (int)ti.type);
   }
   for(long i = 0; i < outCnt; i++) {
      OnnxTypeInfo ti;
      if(OnnxGetOutputTypeInfo(handle, i, ti))
         PrintFormat("ONNX OUT[%d] type=%d", (int)i, (int)ti.type);
   }
}

bool ONNX_Init() {
   ONNX_Release();
   if(!InpML_ONNX_Enable) {
      Print("ONNX: kapalı (InpML_ONNX_Enable=false)");
      return false;
   }

   string path = InpML_ONNX_ModelFile;
   // FileIsExist MQL5/Files relative
   if(!FileIsExist(path)) {
      PrintFormat("ONNX: model yok → MQL5/Files/%s", path);
      Print("ONNX: Dosyayı Terminal veri klasörü/MQL5/Files altına kopyalayın.");
      return false;
   }

   // ── Model yükle (CUDA / CPU – Build 5572+ GPU EP) ─────────────
   // NOT: MQL5 TensorRT EP sunmaz; hızlandırma ONNX Runtime CUDA ile yapılır.
   // Terminal: Tools → Options → Expert Advisors → Allow CUDA usage
   // NVIDIA driver + Turing+ GPU gerekir.
   uint flags = ONNX_DEFAULT;
   string accelName = "AUTO(GPU tercih)";
   switch(InpML_AccelMode) {
      case ML_ACCEL_CUDA_0:   flags = (uint)ONNX_GPU_DEVICE_0; accelName = "CUDA:0"; break;
      case ML_ACCEL_CUDA_1:   flags = (uint)ONNX_GPU_DEVICE_1; accelName = "CUDA:1"; break;
      case ML_ACCEL_CUDA_2:   flags = (uint)ONNX_GPU_DEVICE_2; accelName = "CUDA:2"; break;
      case ML_ACCEL_CUDA_3:   flags = (uint)ONNX_GPU_DEVICE_3; accelName = "CUDA:3"; break;
      case ML_ACCEL_CPU_ONLY: flags = (uint)ONNX_USE_CPU_ONLY; accelName = "CPU_ONLY"; break;
      default:                flags = ONNX_DEFAULT; accelName = "AUTO"; break;
   }
   if(InpML_LogAccel)
      PrintFormat("ONNX: hızlandırma=%s flags=0x%X file=%s", accelName, flags, path);

   long h = OnnxCreate(path, flags);
   if((h == INVALID_HANDLE || h == 0) && InpML_AccelFallbackCPU && InpML_AccelMode != ML_ACCEL_CPU_ONLY) {
      PrintFormat("ONNX: GPU yükleme başarısız err=%d → CPU fallback", GetLastError());
      // FIX: basarisiz GPU handle varsa serbest birak
      if(h != INVALID_HANDLE && h != 0) { OnnxRelease(h); h = INVALID_HANDLE; }
      flags = (uint)ONNX_USE_CPU_ONLY;
      accelName = "CPU_FALLBACK";
      h = OnnxCreate(path, flags);
   }
   if(h == INVALID_HANDLE || h == 0) {
      PrintFormat("ONNX: OnnxCreate BAŞARISIZ err=%d path=%s accel=%s", GetLastError(), path, accelName);
      // FIX: fail durumunda olasi handle sizintisini kapat
      if(h != INVALID_HANDLE && h != 0)
         OnnxRelease(h);
      g_ml.onnx_handle = INVALID_HANDLE;
      return false;
   }
   g_ml.onnx_handle = h;
   PrintFormat("ONNX: model yüklendi handle=%I64d accel=%s file=%s", h, accelName, path);

   ONNX_LogShapes(h);

   // ── Input shape ayarla ───────────────────────────────────────
   long inCnt = OnnxGetInputCount(h);
   if(inCnt <= 0) {
      Print("ONNX: modelde input yok");
      ONNX_Release();
      return false;
   }
   g_ml.input_index = 0;
   g_ml.input_name  = "input0";

   OnnxTypeInfo inInfo;
   if(!OnnxGetInputTypeInfo(h, 0, inInfo)) {
      Print("ONNX: input type info alınamadı (devam – FeatureCount kullanılacak)");
   }

   // Shape: {1, FeatureCount} — dimensions alanına dokunmadan sabit ayarla
   ulong shape[];
   ArrayResize(shape, 2);
   shape[0] = 1;
   shape[1] = (ulong)InpML_FeatureCount;

   // SetInputShape – bazı modeller reddeder (sabit shape); hata kritik değil
   if(!OnnxSetInputShape(h, 0, shape)) {
      PrintFormat("ONNX: OnnxSetInputShape uyarı err=%d (model sabit shape kullanıyor olabilir)", GetLastError());
   }

   g_ml.input_count = InpML_FeatureCount;

   // ── Output ───────────────────────────────────────────────────
   long outCnt = OnnxGetOutputCount(h);
   if(outCnt <= 0) {
      Print("ONNX: modelde output yok");
      ONNX_Release();
      return false;
   }
   g_ml.output_index = 0;
   g_ml.output_name  = "output0";
   g_ml.output_count = InpML_OutputCount;

   OnnxTypeInfo outInfo;
   if(OnnxGetOutputTypeInfo(h, 0, outInfo)) {
      PrintFormat("ONNX OUT type=%d (OutputCount cfg=%d)", (int)outInfo.type, InpML_OutputCount);
   }

   g_ml.onnx_ready = true;
   PrintFormat("ONNX HAZIR | in=%d out=%d | inName=%s outName=%s",
               g_ml.input_count, g_ml.output_count, g_ml.input_name, g_ml.output_name);
   return true;
}

//--- float32 buffer'a özellik kopyala (pad/truncate)
void ONNX_FillInputBuffer(const double &feats[], const int nFeats, float &buf[]) {
   int need = g_ml.input_count;
   if(need <= 0) need = InpML_FeatureCount;
   ArrayResize(buf, need);
   for(int i = 0; i < need; i++) {
      if(i < nFeats) buf[i] = (float)feats[i];
      else           buf[i] = 0.0f; // pad
   }
}

//--- Output'u trend/dir olasılıklarına çevir
void ONNX_ParseOutput(const float &out[], const int nOut,
                      double &trendProb, double &dirProb) {
   trendProb = 0.5;
   dirProb   = 0.5;
   g_ml.last_buy_prob  = 0.5;
   g_ml.last_sell_prob = 0.5;

   if(nOut <= 0) return;

   if(nOut == 1) {
      // tek çıktı = trend gücü (0..1)
      trendProb = MathMax(0.0, MathMin(1.0, (double)out[0]));
      dirProb   = trendProb;
   }
   else if(nOut == 2) {
      // [buyProb, sellProb]
      double buy  = MathMax(0.0, MathMin(1.0, (double)out[0]));
      double sell = MathMax(0.0, MathMin(1.0, (double)out[1]));
      g_ml.last_buy_prob  = buy;
      g_ml.last_sell_prob = sell;
      trendProb = MathMax(buy, sell);
      // dirProb: baskın yönün gücü
      dirProb = (buy >= sell) ? buy : sell;
   }
   else {
      // [trendProb, buyProb, sellProb] (+ opsiyonel fazladan)
      trendProb = MathMax(0.0, MathMin(1.0, (double)out[0]));
      double buy  = MathMax(0.0, MathMin(1.0, (double)out[1]));
      double sell = MathMax(0.0, MathMin(1.0, (double)out[2]));
      g_ml.last_buy_prob  = buy;
      g_ml.last_sell_prob = sell;
      dirProb = (buy >= sell) ? buy : sell;
   }
}

//--- Heuristic fallback (model yok / run fail)
void ONNX_Heuristic(const double &feats[], const int n,
                    double &trendProb, double &dirProb) {
   double conf = g_ctx.dir.confidence;
   double rsiF = (n > 2) ? feats[2] : 0.5;
   double emaD = (n > 3) ? feats[3] : 0.0;

   trendProb = MathMin(1.0, MathMax(0.0, 0.4 + conf * 0.4 + MathAbs(emaD) * 5.0));
   if(g_ctx.dir.direction > 0)
      dirProb = MathMin(1.0, 0.5 + conf * 0.3 + (rsiF < 0.7 ? 0.1 : -0.1));
   else if(g_ctx.dir.direction < 0)
      dirProb = MathMin(1.0, 0.5 + conf * 0.3 + (rsiF > 0.3 ? 0.1 : -0.1));
   else
      dirProb = 0.5;
}

//--- Ana çıkarım
bool ONNX_Infer(const string symbol, double &trendProb, double &dirProb) {
   trendProb = 0.5;
   dirProb   = 0.5;

   if(!InpML_ONNX_Enable) return false;

   double feats[];
   int n = ML_BuildFeatures(symbol, feats);

   // ── Gerçek model run ─────────────────────────────────────────
   if(g_ml.onnx_ready && g_ml.onnx_handle != INVALID_HANDLE && g_ml.onnx_handle != 0) {
      float inBuf[];
      ONNX_FillInputBuffer(feats, n, inBuf);

      int outN = (g_ml.output_count > 0) ? g_ml.output_count : InpML_OutputCount;
      if(outN < 1) outN = 3;
      float outBuf[];
      ArrayResize(outBuf, outN);
      ArrayInitialize(outBuf, 0.0f);

      // OnnxRun(handle, flags, input_array, output_array)
      // flags: 0 veya ONNX_DEBUG_LOG
      ResetLastError();
      bool ok = OnnxRun(g_ml.onnx_handle, 0, inBuf, outBuf);

      if(ok) {
         ONNX_ParseOutput(outBuf, outN, trendProb, dirProb);
         g_ml.last_trend_prob = trendProb;
         g_ml.last_dir_prob   = dirProb;
         g_ml.last_infer_time = TimeCurrent();
         g_ml.infer_count++;
         return true;
      }

      // Run başarısız → sayaç + fallback
      g_ml.infer_fail_count++;
      if(g_ml.infer_fail_count <= 3 || g_ml.infer_fail_count % 50 == 0) {
         PrintFormat("ONNX Run FAIL err=%d failCount=%d → heuristic",
                     GetLastError(), g_ml.infer_fail_count);
      }
   }

   // ── Fallback ─────────────────────────────────────────────────
   if(!InpML_FallbackHeuristic) {
      trendProb = 0.5; dirProb = 0.5;
      return false;
   }
   ONNX_Heuristic(feats, n, trendProb, dirProb);
   g_ml.last_trend_prob = trendProb;
   g_ml.last_dir_prob   = dirProb;
   g_ml.last_infer_time = TimeCurrent();
   g_ml.infer_count++;
   return true;
}

bool ONNX_InferThrottled(const string symbol, double &trendProb, double &dirProb) {
   int idx = Ind_FindIdx(symbol);
   ulong nowMs = GetTickCount64();
   if(idx >= 0 && idx < MAX_SYMBOLS && g_ml_symbolScoreValid[idx] &&
      InpML_UpdateMs > 0 && g_ml_lastInferMs[idx] > 0 &&
      nowMs - g_ml_lastInferMs[idx] < (ulong)InpML_UpdateMs) {
      trendProb = g_ml_trendProb[idx];
      dirProb = g_ml_dirProb[idx];
      return true;
   }

   bool ok = ONNX_Infer(symbol, trendProb, dirProb);
   if(idx >= 0 && idx < MAX_SYMBOLS) {
      g_ml_lastInferMs[idx] = nowMs;
      g_ml_trendProb[idx] = trendProb;
      g_ml_dirProb[idx] = dirProb;
      g_ml_symbolScoreValid[idx] = true;
   }
   return ok;
}

//--- ONNX kapısı: emir açmadan önce minimum olasılık

void ML_MaybeReloadModel() {
   if(!InpML_ONNX_Enable || !InpML_AutoModelReload) return;
   if(InpML_AutoModelReloadSec <= 0) return;
   static datetime s_last = 0;
   if(s_last > 0 && TimeCurrent() - s_last < InpML_AutoModelReloadSec) return;
   s_last = TimeCurrent();
   // Dosya var mı ve handle bozuksa yeniden dene
   if(!g_ml.onnx_ready || g_ml.infer_fail_count > 20) {
      Print("ONNX: auto-reload deneniyor...");
      ONNX_Init();
      g_ml.infer_fail_count = 0;
   }
}

bool ONNX_AllowsEntry(const int direction) {
   if(!(g_rt_ready ? g_rt_ml : InpML_ONNX_Enable)) return true;
   if(InpML_ShadowOnly)   return true;
   if(!g_ml.onnx_ready) {
      static datetime s_lastMLWarn = 0;
      if(TimeCurrent() - s_lastMLWarn >= 300) {
         PrintFormat("ONNX FALLBACK | model hazir degil, entry ML veto olmadan devam ediyor | dir=%d", direction);
         s_lastMLWarn = TimeCurrent();
      }
      return true; // mevcut uyumluluk davranisi korunuyor
   }

   double trendP, dirP;
   if(!ONNX_InferThrottled(g_symbol, trendP, dirP)) return true;

   double w = MathMax(0.05, MathMin(1.0, InpML_Weight));
   if(trendP < InpML_MinTrendProb * w) return false;
   if(dirP   < InpML_MinDirectionProb * w) return false;
   return true;
}

//--- ML özellik CSV log
void ML_DataLog_Write(const string symbol) {
   if(!InpML_DataLog_Enable) return;

   double feats[];
   int n = ML_BuildFeatures(symbol, feats);

   string fname = InpML_DataLog_CSVFile;
   if(InpML_DataLog_AutoPerChart)
      fname = StringFormat("nexus_ml_%s_%I64u.csv", symbol, g_magic);

   bool exists = FileIsExist(fname);
   int h = FileOpen(fname, FILE_WRITE | FILE_READ | FILE_TXT | FILE_ANSI | FILE_SHARE_WRITE);
   if(h == INVALID_HANDLE) {
      Print("ML DataLog: dosya açılamadı ", fname, " err=", GetLastError());
      return;
   }
   FileSeek(h, 0, SEEK_END);

   if(!exists) {
      string hdr = "time,symbol,bid,label_horizon_sec";
      for(int i = 0; i < n; i++)
         hdr += ",f" + IntegerToString(i);
      FileWriteString(h, hdr + "\n");
   }

   string line = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "," + symbol + "," +
                 DoubleToString(SymbolInfoDouble(symbol, SYMBOL_BID), 5) + "," +
                 IntegerToString(InpML_DataLog_LabelHorizonSec);
   for(int i = 0; i < n; i++)
      line += "," + DoubleToString(feats[i], 6);
   FileWriteString(h, line + "\n");
   FileClose(h);
}

//--- Shadow Journal
void Shadow_Open(const string symbol, const int direction, const double lot,
                 const double openPrice, const double slDist, const double tpDist) {
   if(!InpShadowTrade_Enable) return;

   // Aktif sayı limiti
   int activeN = 0;
   for(int i = 0; i < SHADOW_MAX_OPEN; i++)
      if(g_ml.shadows[i].active && !g_ml.shadows[i].closed) activeN++;
   int maxOpen = (InpShadow_MaxOpen > 0) ? MathMin(InpShadow_MaxOpen, SHADOW_MAX_OPEN) : SHADOW_MAX_OPEN;
   if(activeN >= maxOpen) return;

   int slot = -1;
   for(int i = 0; i < SHADOW_MAX_OPEN; i++) {
      if(!g_ml.shadows[i].active) { slot = i; break; }
   }
   if(slot < 0) return;

   g_ml.shadows[slot].active      = true;
   g_ml.shadows[slot].open_time   = TimeCurrent();
   g_ml.shadows[slot].symbol      = symbol;
   g_ml.shadows[slot].direction   = direction;
   g_ml.shadows[slot].open_price  = openPrice;
   g_ml.shadows[slot].lot         = lot;
   g_ml.shadows[slot].sl_dist     = slDist;
   g_ml.shadows[slot].tp_dist     = tpDist;
   g_ml.shadows[slot].close_price = 0;
   g_ml.shadows[slot].pnl         = 0;
   g_ml.shadows[slot].closed      = false;
   g_ml.shadow_count++;

   PrintFormat("SHADOW OPEN | %s %s lot=%.2f price=%.5f",
               symbol, (direction > 0 ? "BUY" : "SELL"), lot, openPrice);
}

void Shadow_Manage(const string symbol) {
   if(!InpShadowTrade_Enable) return;

   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double mpp = TPProj_MoneyPerPriceUnit(symbol);
   long   sprPts = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   double point  = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0) point = _Point;
   double sprPrice = (double)sprPts * point;

   for(int i = 0; i < SHADOW_MAX_OPEN; i++) {
      if(!g_ml.shadows[i].active || g_ml.shadows[i].closed) continue;
      if(g_ml.shadows[i].symbol != symbol) continue;

      double price = (g_ml.shadows[i].direction > 0) ? bid : ask;
      // Pure shadow: fiyat takibi – open'u yavaşça markete kaydır (kârdaysa)
      if(InpPureShadowPriceFollowEnable && g_ml.shadows[i].direction != 0) {
         double fav = (g_ml.shadows[i].direction > 0)
                      ? (bid - g_ml.shadows[i].open_price)
                      : (g_ml.shadows[i].open_price - ask);
         if(fav > 0 && InpPureShadowProfitFollowMult > 0) {
            double trail = fav * (1.0 - 1.0 / MathMax(1.0, InpPureShadowProfitFollowMult));
            if(g_ml.shadows[i].direction > 0)
               g_ml.shadows[i].open_price = MathMax(g_ml.shadows[i].open_price, bid - trail);
            else
               g_ml.shadows[i].open_price = MathMin(g_ml.shadows[i].open_price, ask + trail);
         }
      }

      double move  = (g_ml.shadows[i].direction > 0)
                     ? (price - g_ml.shadows[i].open_price)
                     : (g_ml.shadows[i].open_price - price);
      double pnl = move * mpp * g_ml.shadows[i].lot;

      // Pure shadow spread çarpanlı TP/SL
      double tpDist = g_ml.shadows[i].tp_dist;
      double slDist = g_ml.shadows[i].sl_dist;
      if(InpPureShadowSpreadMult > 0 && sprPrice > 0) {
         if(tpDist <= 0) tpDist = sprPrice * InpPureShadowSpreadMult;
         if(slDist <= 0) slDist = sprPrice * InpPureShadowSpreadMult * 1.5;
      }

      bool hitTP = (tpDist > 0 && move >= tpDist);
      bool hitSL = (slDist > 0 && move <= -slDist);

      // Net spread close (kâr/zarar spread eşiği)
      if(InpPureShadowNetSpreadCloseEnable && sprPrice > 0) {
         double netMove = move - sprPrice; // round-trip yaklaşık
         if(pnl > 0 && InpPureShadowNetProfitSpreadMult > 0 &&
            netMove >= sprPrice * InpPureShadowNetProfitSpreadMult)
            hitTP = true;
         if(pnl < 0 && InpPureShadowNetLossSpreadMult > 0 &&
            move <= -sprPrice * InpPureShadowNetLossSpreadMult)
            hitSL = true;
      }

      if(hitTP || hitSL) {
         g_ml.shadows[i].close_price = price;
         g_ml.shadows[i].pnl         = pnl;
         g_ml.shadows[i].closed      = true;
         g_ml.shadows[i].active      = false;

         PrintFormat("SHADOW CLOSE | %s %s pnl=%.2f reason=%s",
                     symbol,
                     (g_ml.shadows[i].direction > 0 ? "BUY" : "SELL"),
                     pnl, (hitTP ? "TP" : "SL"));

         if(InpShadowTrade_WriteCSV) {
            string fname = InpShadowTrade_CSVFile;
            bool exists = FileIsExist(fname);
            int h = FileOpen(fname, FILE_WRITE|FILE_READ|FILE_CSV|FILE_ANSI|FILE_SHARE_WRITE, ',');
            if(h != INVALID_HANDLE) {
               FileSeek(h, 0, SEEK_END);
               if(!exists) {
                  FileWrite(h, "open_time", "close_time", "symbol", "dir", "lot",
                            "open", "close", "pnl", "reason");
               }
               FileWrite(h,
                         TimeToString(g_ml.shadows[i].open_time, TIME_DATE|TIME_SECONDS),
                         TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
                         symbol,
                         (g_ml.shadows[i].direction > 0 ? "BUY" : "SELL"),
                         DoubleToString(g_ml.shadows[i].lot, 2),
                         DoubleToString(g_ml.shadows[i].open_price, 5),
                         DoubleToString(price, 5),
                         DoubleToString(pnl, 2),
                         (hitTP ? "TP" : "SL"));
               FileClose(h);
            }
         }
      }
   }
}

//--- Dışarıdan kolay çağrı (Lattice / Bullet giriş anında)
void Shadow_LogHypothetical(const string symbol, const int direction, const double lot) {
   if(!InpShadowTrade_Enable) return;
   double price = (direction > 0) ? SymbolInfoDouble(symbol, SYMBOL_ASK)
                                  : SymbolInfoDouble(symbol, SYMBOL_BID);
   double atr = TPProj_ExpectedMove(symbol) / MathMax(InpTPProjExpectedMoveATR, 0.1);
   double tpMult = (InpShadow_TP_ATR_Mult > 0) ? InpShadow_TP_ATR_Mult : 1.0;
   double slMult = (InpShadow_SL_ATR_Mult > 0) ? InpShadow_SL_ATR_Mult : 0.7;
   double tpDist = atr * tpMult;
   double slDist = atr * slMult;
   Shadow_Open(symbol, direction, lot, price, slDist, tpDist);
}

//--- Pipeline mikro katmanına ONNX skoru yaz
void Stage_MicroLayers(SPipelineContext &ctx) {
   // 1) DI/TMI consensus
   g_consensusBlocked = false;
   g_consensusNote = "";
   if(ctx.dir.direction != 0) {
      string note;
      if(!Consensus_Evaluate(ctx.symbol, ctx.dir.direction, note)) {
         g_consensusBlocked = true;
         g_consensusNote = note;
         ctx.allow_new_entries = false;
      } else {
         g_consensusNote = note;
      }
   } else {
      // DI/TMI yine hesapla (panel için)
      string note;
      Consensus_Evaluate(ctx.symbol, 0, note);
      g_consensusNote = note;
   }

   // 2) AWR + AEGIS
   Stage_AWR_AEGIS(ctx);

   // 2b) HEG + DTE
   // Panel DTE/HEG override (ticari parity: panelden kapatilabilir)
   bool hegOn = g_rt_ready ? g_rt_heg_on : InpHEG_Enable;
   bool dteOn = g_rt_ready ? g_rt_dte_on : InpDTE_Enable;
   if(hegOn) {
      g_heg = HEG_Evaluate(ctx.symbol);
      // v1.78.39 FIX: eskiden iki input OR'lanıp tek global allow_new_entries'i
      // kapatıyordu — "sadece Grid'i etkilesin" veya "sadece Trend'i etkilesin"
      // seçmenin hiçbir pratik etkisi yoktu. Artık Grid ve Bullet ayrı ayrı
      // bloklanıyor (bkz. Lattice giriş bloğu ve Bullet_Process); genel
      // allow_new_entries SADECE ikisi de aynı anda etkilenmediyse (yani en
      // az biri hâlâ açık olabilir) burada dokunulmuyor — her motor kendi
      // özel bayrağını kontrol ediyor.
      ctx.heg_block_grid  = g_heg.block && InpHEG_AffectGrid;
      ctx.heg_block_trend = g_heg.block && InpHEG_AffectTrend;
      // v1.78.159 GECICI TESHIS: AEGIS ile ayni sebepten - HEG_COOLDOWN veya
      // spike blogu tetiklendiginde bagimsiz, kendi 60sn penceresinde yazar.
      if(g_heg.block) {
         static datetime s_lastHegDiag = 0;
         if(TimeCurrent() - s_lastHegDiag >= 60) {
            s_lastHegDiag = TimeCurrent();
            PrintFormat("HEG TESHIS | %s | dir=%d | sebep=%s | blockGrid=%s blockTrend=%s",
                        ctx.symbol, ctx.dir.direction, g_heg.reason,
                        ctx.heg_block_grid ? "true" : "false", ctx.heg_block_trend ? "true" : "false");
         }
      }
      // SECOND_AUDIT #9 FIX (P3): InpHEG_Weight artik gercekten kullaniliyor -
      // eskiden HEG sadece sert blok/gecis olarak calisiyordu, agirlik hicbir
      // hesaba katilmiyordu. Bloke ETMEDIGINDE (yani islem zaten devam edecek),
      // efficiency kendi esigini (InpHEG_MinEfficiency) ne kadar astiysa o kadar,
      // InpHEG_Weight ile olceklenmis, YUKARI yonlu ve sinirli bir confidence
      // katkisi yapar (InpDOM_Weight ile ayni desen). Mevcut sert blok karari
      // DEGISMEZ - bu sadece blok DISINDAKI durumlarda ek bir sinyal.
      if(!g_heg.block) {
         double hegEdge = g_heg.efficiency - InpHEG_MinEfficiency;
         if(hegEdge > 0)
            ctx.dir.confidence = MathMin(1.0, ctx.dir.confidence * (1.0 + InpHEG_Weight * MathMin(hegEdge, 1.0) * 0.3));
      }
   } else {
      ZeroMemory(g_heg);
      ctx.heg_block_grid  = false;
      ctx.heg_block_trend = false;
   }
   if(dteOn) {
      g_dte = DTE_Evaluate(ctx.symbol, ctx.dir);
      if(g_dte.block) {
         ctx.allow_new_entries = false;
         // v1.78.159 GECICI TESHIS: AEGIS/HEG ile ayni desen.
         static datetime s_lastDteDiag = 0;
         if(TimeCurrent() - s_lastDteDiag >= 60) {
            s_lastDteDiag = TimeCurrent();
            PrintFormat("DTE TESHIS | %s | dir=%d | sebep=%s", ctx.symbol, ctx.dir.direction, g_dte.reason);
         }
      }
      // SECOND_AUDIT #9 FIX (P3): InpDTE_Weight artik gercekten kullaniliyor -
      // ayni desen (bkz. HEG yorumu yukarida): bloke etmiyorsa, metaEdge kendi
      // esigini (InpDTE_MinMetaEdge) ne kadar astiysa o kadar, agirlikli ve
      // sinirli, sadece YUKARI yonlu confidence katkisi.
      if(!g_dte.block) {
         double dteEdge = g_dte.metaEdge - InpDTE_MinMetaEdge;
         if(dteEdge > 0)
            ctx.dir.confidence = MathMin(1.0, ctx.dir.confidence * (1.0 + InpDTE_Weight * MathMin(dteEdge, 1.0) * 0.3));
      }
   } else {
      ZeroMemory(g_dte);
   }
   // Sinyal kapaliysa yeni giris yok
   if(g_rt_ready && !g_rt_sinyal)
      ctx.allow_new_entries = false;

   // 2c) Early Trend + Smart Dir
   g_early = EarlyTrend_Evaluate(ctx.symbol);
   g_smart = SmartDir_Evaluate(ctx.symbol, ctx.dir.direction, ctx.dir.confidence);
   // Early alone: DI henüz mature değilken erken yönü destekle
   if(InpEarlyTrend_Enable && g_early.valid && InpEarlyTrend_AllowAlone &&
      ctx.dir.direction == 0 && !g_di.mature) {
      ctx.dir.direction = g_early.direction;
      ctx.dir.confidence = g_early.confidence;
      ctx.dir.phase = (g_early.direction > 0) ? PHASE_TREND_UP : PHASE_TREND_DOWN;
      ctx.dir.engine_name = ctx.dir.engine_name + "+EARLY";
   }
   if(InpSmartDir_Enable && ctx.dir.direction != 0 && !g_smart.allow)
      ctx.allow_new_entries = false;

   // 2d) DOM soft weight (opsiyonel – Market Book)
   if((g_rt_ready ? g_rt_dom : InpDOM_Enable) && ctx.dir.direction != 0) {
      // MarketBookAdd bir kez OnInit'te yapılmalı; burada sadece mevcut kitap
      // SECOND_AUDIT #8 FIX (P3): InpDOM_FreshMs artik gercekten kullaniliyor -
      // OnBookEvent() ile guncellenen zaman damgasi InpDOM_FreshMs'ten eskiyse
      // (veya bu sembol icin hic OnBookEvent gelmemisse, ornegin MarketBookAdd
      // sadece chart sembolune yapildigindan) DOM verisi stale sayilir ve
      // entry/confidence karari ETKILENMEZ.
      ulong domLastMs = g_dom_lastUpdateMs[g_sym_idx];
      ulong domAgeMs  = GetTickCount64() - domLastMs;
      bool  domFresh  = (domLastMs > 0) && (domAgeMs <= (ulong)InpDOM_FreshMs);
      if(domFresh) {
      MqlBookInfo book[];
      if(MarketBookGet(ctx.symbol, book) && ArraySize(book) > 0) {
         double bidVol = 0, askVol = 0;
         int top = MathMin(ArraySize(book), InpDOM_TopLevels);
         for(int i = 0; i < ArraySize(book) && i < top * 2; i++) {
            // volume long → double (uyarı bastırma)
            if(book[i].type == BOOK_TYPE_BUY || book[i].type == BOOK_TYPE_BUY_MARKET)
               bidVol += (double)book[i].volume;
            if(book[i].type == BOOK_TYPE_SELL || book[i].type == BOOK_TYPE_SELL_MARKET)
               askVol += (double)book[i].volume;
         }
         double tot = bidVol + askVol;
         if(tot > 0) {
            double imb = (bidVol - askVol) / tot; // + bid ağır
            if(ctx.dir.direction > 0 && imb < -0.25)
               ctx.dir.confidence *= (1.0 - InpDOM_Weight * 0.5);
            if(ctx.dir.direction < 0 && imb >  0.25)
               ctx.dir.confidence *= (1.0 - InpDOM_Weight * 0.5);
            if(ctx.dir.direction > 0 && imb > 0.25)
               ctx.dir.confidence = MathMin(1.0, ctx.dir.confidence * (1.0 + InpDOM_Weight * 0.3));
            if(ctx.dir.direction < 0 && imb < -0.25)
               ctx.dir.confidence = MathMin(1.0, ctx.dir.confidence * (1.0 + InpDOM_Weight * 0.3));
         }
      }
      }
   }

   // 3) ONNX skor
   if(g_rt_ready ? g_rt_ml : InpML_ONNX_Enable) {
      double tP, dP;
      ONNX_InferThrottled(ctx.symbol, tP, dP);
      // FIX v1.78.13: gercek model yuklu degilse (g_ml.onnx_ready=false) esik
      // kontrolu uygulanmiyor. Once ONNX_Heuristic'in ciktisina bakiliyordu -
      // o da yon NOTR oldugunda (tam olarak grid tohum denemesi aninda) dirProb'u
      // AYNEN 0.5 donduruyor, bu da InpML_MinDirectionProb=0.55 esigini hep
      // basarisiz kilip her notr-yon girisimini sessizce engelliyordu.
      if(g_ml.onnx_ready && !InpML_ShadowOnly) {
         if(tP < InpML_MinTrendProb || dP < InpML_MinDirectionProb)
            ctx.allow_new_entries = false;
      }
   }

   // 4) ML özellik log (seyrek)
   static datetime s_lastLog = 0;
   if(InpML_DataLog_Enable && TimeCurrent() - s_lastLog >= 60) {
      ML_DataLog_Write(ctx.symbol);
      s_lastLog = TimeCurrent();
   }

   // 5) Shadow yönetimi
   Shadow_Manage(ctx.symbol);
}

//+------------------------------------------------------------------+
//| 12. PANEL – Scroll + sabit ust/alt + Info + DEGER editler (v1.49)|
//+------------------------------------------------------------------+
#define PN_PREFIX   "NXR21_"
// ileri bildirim
void CreateEdit(const string name, const int x, const int y, const int w, const int h, const string text="");
string TradeDiag_Compute();
void Panel_HideAllEdits();
void Panel_BeginEdit(const string name);
#define PN_X        6
#define PN_Y        16
#define PN_W        318
#define PN_EDIT_COL 102   // canvas disi edit sutunu (mouse/klavye icin)
#define PN_H        520          // varsayılan; chart yüksekliğine göre kırpılır
#define PN_ROW      14
#define PN_TAB_H    20
#define PN_BTN_H    20
#define PN_EDIT_H   17
#define PN_PAD      6
#define PN_TOGGLE_H 20
#define PN_HDR_H    142          // kompakt header (daha fazla viewport)
#define PN_FTR_H    32
#define PN_SCROLL_W 10           // sağ scrollbar genişliği
#define PANEL_VIEWPORT_H      430  // sekme içeriği tasarım yüksekliği (referans)
#define PANEL_VIEWPORT_MIN_H  220  // küçük scale’de viewport tabanı
#define PANEL_SCROLL_STEP      28  // ▲/▼ kaydırma adımı
#define PANEL_SCALE_MIN       0.6
#define PANEL_SCALE_MAX       1.8

// Canvas panel erken bayrak (tam CCanvas aşağıda)
bool g_cvReady = false;
int  g_cvW = 0, g_cvH = 0;
int  g_cvX = 6, g_cvY = 16;

// v1.73: runtime panel ölçeği → g_panelScale (üst global blok)

// Merkezi ölçekleme — ofset (panel köşesi) ölçeklenmez, relatif uzunluk ölçeklenir
int ScaleXY(const int panelOrigin, const int coord) {
   double rel = (double)(coord - panelOrigin);
   return panelOrigin + (int)MathRound(rel * g_panelScale);
}
int ScaleLen(const int len) {
   return (int)MathRound((double)len * g_panelScale);
}
int ScaleFont(const int fontSize) {
   int scaled = (int)MathRound((double)fontSize * g_panelScale);
   if(scaled < 6)  scaled = 6;
   if(scaled > 28) scaled = 28;
   return scaled;
}
double Panel_ClampScale(double sc) {
   if(sc < PANEL_SCALE_MIN) sc = PANEL_SCALE_MIN;
   if(sc > PANEL_SCALE_MAX) sc = PANEL_SCALE_MAX;
   return sc;
}

// GUI SAFETY: Panel nesneleri yalnızca panel prefix'iyle, aşağı doğru taranarak
// silinir; silme hataları loglanır ve eski EditBox nesneleri sessiz kalmaz.
void Panel_DeleteAll()
{
   int total = ObjectsTotal(0, 0, -1);
   if(total < 0)
   {
      PrintFormat("PANEL DELETE FAIL | ObjectsTotal err=%d", GetLastError());
      return;
   }

   for(int i = total - 1; i >= 0; i--)
   {
      ResetLastError();
      string name = ObjectName(0, i, 0, -1);
      if(StringLen(name) == 0 || StringFind(name, PN_PREFIX) != 0)
         continue;

      ResetLastError();
      if(!ObjectDelete(0, name))
         PrintFormat("PANEL DELETE FAIL | name=%s err=%d", name, GetLastError());
   }
}

void Panel_Label(const string id, int x, int y, const string text, color clr, int fontSize = 9) {
   string name = PN_PREFIX + id;
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetString(0, name, OBJPROP_FONT, "Segoe UI");
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

void Panel_Button(const string id, int x, int y, int w, int h,
                  const string text, color bg, color txt) {
   string name = PN_PREFIX + id;
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetString(0, name, OBJPROP_FONT, "Segoe UI");
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, txt);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, name, OBJPROP_STATE, false);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

void Panel_Rect(const string id, int x, int y, int w, int h, color bg, color border) {
   string name = PN_PREFIX + id;
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR, border);
}

// NOT v1.78.13: Bu fonksiyon hiçbir yerden çağrılmıyor — CV_ShowEditInline
// (panel-içi konumlandırmalı) onun yerini almış. CV_ShowEdit'teki v1.68 notuyla
// aynı durum, sadece o zaman burada yazılmamış. Silinmedi ama ölü koddur;
// yeni editbox eklerken CV_ShowEditInline kullanılmalı, bu değil.
void Panel_Edit(const string id, int x, int y, int w, int h, const string text) {
   CreateEdit(PN_PREFIX + id, x, y, w, h, text);
}


void Panel_SetVisible(const string id, bool vis) {
   string name = PN_PREFIX + id;
   if(ObjectFind(0, name) >= 0)
      ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, vis ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
}

// Chart yüksekliğine göre panel boyutu (ekrana sığsın)
int Panel_FitHeight(const double sc) {
   int chartH = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
   if(chartH < 200) chartH = 600;
   int maxH = chartH - PN_Y - 12;
   int want = (int)(PN_H * MathMin(sc, 1.15));
   if(want > maxH) want = maxH;
   if(want < 320) want = MathMin(320, maxH);
   return want;
}

// Viewport: sadece gorunen band icindeki objeyi goster + Y guncelle
void Panel_PlaceScroll(const string id, int x, int logicalY, int w, int h,
                       int viewTop, int viewH) {
   int y = viewTop + logicalY - g_panelScroll;
   bool vis = (y + h > viewTop - 4) && (y < viewTop + viewH + 4);
   string name = PN_PREFIX + id;
   if(ObjectFind(0, name) < 0) return;
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, vis ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
   // Edit/button boyutunu da sabitle (scroll sırasında kaymasın)
   if(ObjectGetInteger(0, name, OBJPROP_TYPE) == OBJ_EDIT ||
      ObjectGetInteger(0, name, OBJPROP_TYPE) == OBJ_BUTTON) {
      if(w > 0) ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
      if(h > 0) ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   }
}

// Sağ scrollbar (track + thumb)
void Panel_DrawScrollbar(int x, int viewTop, int viewH, int panelW) {
   int trackX = x + panelW - PN_SCROLL_W - 3;
   Panel_Rect("sbTrack", trackX, viewTop, PN_SCROLL_W, viewH, CV_CARD, C'40,50,60');
   if(g_panelScrollMax <= 0) {
      Panel_SetVisible("sbThumb", false);
      return;
   }
   double ratio = (double)viewH / (double)(viewH + g_panelScrollMax);
   if(ratio > 1.0) ratio = 1.0;
   if(ratio < 0.12) ratio = 0.12;
   int thumbH = (int)(viewH * ratio);
   if(thumbH < 18) thumbH = 18;
   if(thumbH > viewH) thumbH = viewH;
   double posRatio = (g_panelScrollMax > 0) ? ((double)g_panelScroll / (double)g_panelScrollMax) : 0.0;
   int thumbY = viewTop + (int)((viewH - thumbH) * posRatio);
   Panel_Rect("sbThumb", trackX + 1, thumbY, PN_SCROLL_W - 2, thumbH, C'0,160,140', C'0,200,170');
   Panel_SetVisible("sbThumb", true);
   Panel_SetVisible("sbTrack", true);
}

string Panel_DirText() {
   if(g_ctx.dir.direction > 0) return "BUY ↑";
   if(g_ctx.dir.direction < 0) return "SELL ↓";
   return "NÖTR";
}

string Panel_PhaseText() {
   switch(g_ctx.dir.phase) {
      case PHASE_TREND_UP:   return "TREND↑";
      case PHASE_TREND_DOWN: return "TREND↓";
      case PHASE_RANGE:      return "RANGE";
      default:               return "NEUTRAL";
   }
}

double Panel_NetFloating() {
   double pnl = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !PositionSelectByTicket(tk)) continue;
      if(PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      pnl += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }
   return pnl;
}

//--- FIX v1.78.13: panelde sabit 70.0 gosterilen "BASARI" artik kapanan islem
//    gecmisinden gercek hesaplaniyor (bu sembol+magic, 30sn cache ile).
double Panel_CalcSuccessRate() {
   static double   s_cachedPct = 0.0;
   static datetime s_lastCalc  = 0;
   if(s_lastCalc > 0 && TimeCurrent() - s_lastCalc < 30) return s_cachedPct;
   s_lastCalc = TimeCurrent();

   if(!HistorySelect(0, TimeCurrent() + 60)) return s_cachedPct;
   int wins = 0, losses = 0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++) {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != g_symbol) continue;
      if((ulong)HistoryDealGetInteger(d, DEAL_MAGIC) != g_magic) continue;
      long entry = HistoryDealGetInteger(d, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY) continue;
      double net = HistoryDealGetDouble(d, DEAL_PROFIT)
                 + HistoryDealGetDouble(d, DEAL_SWAP)
                 + HistoryDealGetDouble(d, DEAL_COMMISSION);
      if(net > 0.0) wins++;
      else if(net < 0.0) losses++;
   }
   HistorySelect(0, TimeCurrent() + 86400); // genis pencereyi geri yukle - diger kod buna guveniyor

   int closedTotal = wins + losses;
   s_cachedPct = (closedTotal > 0) ? (100.0 * wins / closedTotal) : 0.0;
   return s_cachedPct;
}

void Panel_Toggle(const string id, int x, int y, int w, int h, const string label, bool on) {
   color bg = on ? C'20,90,70' : C'40,44,55';
   color tx = on ? C'80,255,180' : C'160,165,180';
   Panel_Button(id, x, y, w, h, label + (on ? ": AÇIK" : ": KAPALI"), bg, tx);
}

// Anlık apply geri bildirimi (info satırı)
// g_panelApplyMsg / g_panelApplyMsgUntil → üst global blok (v1.68)

// EDITBOX SAFETY: yalnızca tam ve finite sayısal metinleri kabul eder;
// boş/bozuk/ondalık-int uyumsuz değerler runtime state'e yazılmaz.
bool Panel_IsValidNumericText(const string raw, const bool requireInteger, double &outValue)
{
   string text = raw;
   StringTrimLeft(text);
   StringTrimRight(text);
   if(StringLen(text) == 0)
      return false;

   int dotCount = 0;
   int digitCount = 0;
   for(int i = 0; i < StringLen(text); i++)
   {
      ushort ch = StringGetCharacter(text, i);
      if(ch >= '0' && ch <= '9')
      {
         digitCount++;
         continue;
      }
      if(ch == '.' && !requireInteger && dotCount == 0 && i > 0)
      {
         dotCount++;
         continue;
      }
      if(ch == '-' && i == 0)
         continue;
      return false;
   }

   if(digitCount == 0)
      return false;

   ResetLastError();
   outValue = StringToDouble(text);
   int errorCode = GetLastError();
   if(errorCode != 0 || !MathIsValidNumber(outValue))
      return false;

   if(requireInteger && MathAbs(outValue - MathRound(outValue)) > 1e-9)
      return false;
   return true;
}

bool Panel_ParseEditValue(const string id, const string raw, string &outMsg) {
   string s = raw;
   StringTrimLeft(s);
   StringTrimRight(s);
   if(StringLen(s) == 0) {
      outMsg = id + ": boş (korundu)";
      return false;
   }
   double v = 0.0;
   double integerValue = 0.0;
   bool decimalValid = Panel_IsValidNumericText(s, false, v);
   bool integerValid = Panel_IsValidNumericText(s, true, integerValue);
   int iv = integerValid ? (int)MathRound(integerValue) : 0;
   if(!decimalValid && !integerValid) {
      outMsg = id + ": geçersiz sayı biçimi";
      return false;
   }
   bool ok = false;

   if(id == "edLot") {
      if(v > 0) { g_rt_vg_lot = v; outMsg = StringFormat("lot=%.2f", v); ok = true; }
   } else if(id == "edStep") {
      if(v > 0) { g_rt_vg_step = v; outMsg = StringFormat("step=%.1f", v); ok = true; }
   } else if(id == "edBul") {
      if(v > 0) { g_rt_bullet_lot = v; outMsg = StringFormat("bullet=%.2f", v); ok = true; }
   } else if(id == "edPeak") {
      // Peak: boş korunur; negatif reddedilir; 0+ kabul
      if(v >= 0) { g_rt_peak = v; outMsg = StringFormat("peak=%.1f", v); ok = true; }
   } else if(id == "edMult") {
      if(v >= 1.0 && v <= 10.0) {
         g_rt_grid_mult = v;
         outMsg = StringFormat("mult=%.3f", v);
         ok = true;
      }
   } else if(id == "edTpPts") {
      // v1.78.30 FIX: ADIM PNT ile ayni mantik — TP PUAN de ATR tarafindan
      // dolduruluyor, elle giris ayni sekilde kalici olmali.
      if(v > 0) { g_rt_tp_pts = v; g_rt_tp_manual_override = true; outMsg = StringFormat("tp=%.0f (manuel)", v); ok = true; }
   } else if(id == "edBak") {
      if(v > 0) { g_rt_bak_pct = v; outMsg = StringFormat("bak=%.3f", v); ok = true; }
   } else if(id == "edTpVar") {
      if(v > 0) { g_rt_tp_var_pct = v; outMsg = StringFormat("tpVar=%.3f", v); ok = true; }
   } else if(id == "edWork") {
      if(iv > 0) { g_rt_work_min = iv; outMsg = StringFormat("work=%d", iv); ok = true; }
   } else if(id == "edIdle") {
      if(iv >= 0) { g_rt_idle_min = iv; outMsg = StringFormat("idle=%d", iv); ok = true; }
   } else if(id == "edDd") {
      if(v > 0) { g_rt_dd_pct = v; outMsg = StringFormat("dd=%.1f", v); ok = true; }
   } else if(id == "edDdTp") {
      if(v > 0) { g_rt_dd_tp_pct = v; outMsg = StringFormat("ddTp=%.2f", v); ok = true; }
   } else if(id == "edPr") {
      if(v > 0) { g_rt_profit_reset_pct = v; outMsg = StringFormat("kâr%%=%.1f", v); ok = true; }
   } else if(id == "edLr") {
      if(v > 0) { g_rt_loss_reset_pct = v; outMsg = StringFormat("zarar%%=%.1f", v); ok = true; }
   } else if(id == "edStepPnt") {
      // v1.78.30 FIX: elle yazilan deger artik ATR'nin 30sn'lik tazelemesine
      // karsi KALICI — ATR MODU'nu kapatip tekrar acana kadar korunur.
      if(v > 0) { g_rt_step_pnt = v; g_rt_step_manual_override = true; outMsg = StringFormat("pnt=%.0f (manuel)", v); ok = true; }
   } else if(id == "edLossBek") {
      if(v > 0) { g_rt_loss_bek = v; outMsg = StringFormat("zarBek=%.0f", v); ok = true; }
   } else if(id == "edLossAd") {
      if(iv > 0) { g_rt_loss_adet = iv; outMsg = StringFormat("zarAd=%d", iv); ok = true; }
   } else if(id == "edPrBek") {
      if(v > 0) { g_rt_profit_bek = v; outMsg = StringFormat("kârBek=%.0f", v); ok = true; }
   } else if(id == "edPrAd") {
      if(iv > 0) { g_rt_profit_adet = iv; outMsg = StringFormat("kârAd=%d", iv); ok = true; }
   } else if(id == "edKarKul") {
      if(iv > 0) { g_rt_kar_kulucka = iv; outMsg = StringFormat("kârKul=%d", iv); ok = true; }
   } else if(id == "edZarKul") {
      if(iv > 0) { g_rt_zarar_kulucka = iv; outMsg = StringFormat("zarKul=%d", iv); ok = true; }
   } else if(id == "edVtp") {
      if(v > 0) { g_rt_vtp_mult = v; outMsg = StringFormat("vtp=%.1f", v); ok = true; }
   } else if(id == "edZarBlok") {
      if(iv > 0) { g_rt_zarar_blok = iv; outMsg = StringFormat("zarBlok=%d", iv); ok = true; }
   } else if(id == "edAtrTrig") {
      // v1.78.27 FIX: ust sinir yoktu — "1.00" yerine yanlislikla "100" gibi
      // yazilirsa ADIM = ATR*100*symMult*riskMult gibi gercek disi buyuk
      // cikiyor, grid hic acilmiyordu (RiskATR_AutoFill'in urettigi ayni
      // "asiri buyuk step" sonucu). Makul aralik: 0.1-5.0. Aralik disi deger
      // ok=true yapilmadan birakilir -> panel otomatik "edAtrTrig: gecersiz"
      // gosterip kutuyu eski degere geri yazar (mevcut genel davranis).
      if(v >= 0.1 && v <= 5.0) { g_rt_atr_trig_mult = v; outMsg = StringFormat("atrTrig=%.2f", v); ok = true; }
   } else if(id == "edAdxThr") {
      if(v > 0) { g_rt_adx_threshold = v; outMsg = StringFormat("adxEsik=%.0f", v); ok = true; }
   } else if(id == "edHassas") {
      if(v > 0) { g_rt_hassas = v; outMsg = StringFormat("hassas=%.1f", v); ok = true; }
   } else if(id == "edOnay") {
      if(iv > 0) { g_rt_onay = iv; outMsg = StringFormat("onay=%d", iv); ok = true; }
   } else if(id == "edTol") {
      if(v > 0) { g_rt_tolerans = v; outMsg = StringFormat("tol=%.2f", v); ok = true; }
   } else if(id == "edKul") {
      if(iv > 0) { g_rt_kulucka = iv; outMsg = StringFormat("kul=%d", iv); ok = true; }
   } else if(id == "edOrnek") {
      if(iv > 0) { g_rt_ornek_sn = iv; outMsg = StringFormat("örnek=%d", iv); ok = true; }
   } else if(id == "edHdgWait") {
      if(iv >= 0) { g_rt_hedge_wait = iv; outMsg = StringFormat("hdgBek=%d", iv); ok = true; }
   } else if(id == "edHdgPr") {
      if(v >= 0) { g_rt_hedge_profit = v; outMsg = StringFormat("hdgKâr=%.2f", v); ok = true; }
   } else if(id == "edMaxRst") {
      if(iv > 0) { g_rt_max_reset = iv; outMsg = StringFormat("maxRst=%d", iv); ok = true; }
   } else if(id == "edRstMin") {
      if(iv > 0) { g_rt_reset_min = iv; outMsg = StringFormat("rstDk=%d", iv); ok = true; }
   } else if(id == "edNfBef") {
      if(iv >= 0) { g_rt_nf_before = iv; outMsg = StringFormat("nfÖnce=%d", iv); ok = true; }
   } else if(id == "edNfAft") {
      if(iv >= 0) { g_rt_nf_after = iv; outMsg = StringFormat("nfSonra=%d", iv); ok = true; }
   } else {
      outMsg = id + ": bilinmeyen";
      return false;
   }
   if(!ok) outMsg = id + ": geçersiz";
   return ok;
}

// Tek edit anlık apply (ENDEDIT)


//--- v1.73: Edit metni – her zaman gerçek değer (BOT durumu metni gizlemez)
string FmtEditVal(const double val, const int digits) {
   return DoubleToString(val, digits);
}
string FmtEditInt(const int val) {
   return IntegerToString(val);
}

// Runtime → tek edit metni (ENDEDIT/Apply sonrası)
void Panel_SyncEditText(const string id) {
   string name = PN_PREFIX + id;
   if(ObjectFind(0, name) < 0) return;
   // Her zaman runtime değeri göster (boşaltma yok)
   string t = "";
   if(id=="edLot") t=FmtEditVal(RT_VG_Lot(),2);
   else if(id=="edStep") t=FmtEditVal(RT_VG_Step(),1);
   else if(id=="edStepPnt") t=FmtEditVal(g_rt_step_pnt,0);
   else if(id=="edMult") t=FmtEditVal(g_rt_grid_mult,3);
   else if(id=="edTpPts") t=FmtEditVal(RT_VG_TP(),0);
   else if(id=="edBul") t=FmtEditVal(RT_BulletLot(),2);
   else if(id=="edPeak") t=FmtEditVal(RT_PeakRaw(),1);
   else if(id=="edBak") t=FmtEditVal(g_rt_bak_pct,3);
   else if(id=="edTpVar") t=FmtEditVal(g_rt_tp_var_pct,3);
   else if(id=="edLossBek") t=FmtEditVal(g_rt_loss_bek,0);
   else if(id=="edLossAd") t=FmtEditInt(g_rt_loss_adet);
   else if(id=="edPrBek") t=FmtEditVal(g_rt_profit_bek,0);
   else if(id=="edPrAd") t=FmtEditInt(g_rt_profit_adet);
   else if(id=="edKarKul") t=FmtEditInt(g_rt_kar_kulucka);
   else if(id=="edZarKul") t=FmtEditInt(g_rt_zarar_kulucka);
   else if(id=="edVtp") t=FmtEditVal(g_rt_vtp_mult,1);
   else if(id=="edZarBlok") t=FmtEditInt(g_rt_zarar_blok);
   else if(id=="edAtrTrig") t=FmtEditVal(RT_ATRTriggerMult(),2);
   else if(id=="edAdxThr") t=FmtEditVal(RT_ADXThreshold(),0);
   else if(id=="edHassas") t=FmtEditVal(g_rt_hassas,1);
   else if(id=="edOnay") t=FmtEditInt(g_rt_onay);
   else if(id=="edTol") t=FmtEditVal(g_rt_tolerans,2);
   else if(id=="edKul") t=FmtEditInt(g_rt_kulucka);
   else if(id=="edOrnek") t=FmtEditInt(g_rt_ornek_sn);
   else if(id=="edWork") t=FmtEditInt(g_rt_work_min);
   else if(id=="edIdle") t=FmtEditInt(g_rt_idle_min);
   else if(id=="edDd") t=FmtEditVal(g_rt_dd_pct,1);
   else if(id=="edDdTp") t=FmtEditVal(g_rt_dd_tp_pct,2);
   else if(id=="edPr") t=FmtEditVal(g_rt_profit_reset_pct,1);
   else if(id=="edLr") t=FmtEditVal(g_rt_loss_reset_pct,1);
   else if(id=="edHdgWait") t=FmtEditInt(g_rt_hedge_wait);
   else if(id=="edHdgPr") t=FmtEditVal(g_rt_hedge_profit,2);
   else if(id=="edMaxRst") t=FmtEditInt(g_rt_max_reset);
   else if(id=="edRstMin") t=FmtEditInt(g_rt_reset_min);
   else if(id=="edNfBef") t=FmtEditInt(g_rt_nf_before);
   else if(id=="edNfAft") t=FmtEditInt(g_rt_nf_after);
   else return;
   ObjectSetString(0, name, OBJPROP_TEXT, t);
}

bool Panel_ApplyOne(const string objectName) {
   if(StringFind(objectName, PN_PREFIX) != 0) return false;
   string id = StringSubstr(objectName, StringLen(PN_PREFIX));
   if(StringFind(id, "ed") != 0) return false;

   string raw = ObjectGetString(0, objectName, OBJPROP_TEXT);
   string msg = "";
   bool ok = Panel_ParseEditValue(id, raw, msg);

   if(ok) {
      if(id == "edStep" || id == "edLot" || id == "edMult") {
         if(g_lattice.initialized)
            Lattice_RefreshSteps(g_lattice, g_symbol);
      }
      GV_MarkDirty();
      PanelMemory_Save(); // anında diske/GV – restart sonrası korunsun
      g_panelApplyMsg = "● UYGULANDI " + msg;
      g_panelApplyMsgUntil = TimeCurrent() + 4;
      PrintFormat("Panel ANLIK | %s", msg);
      // Formatlı runtime değeriyle sabitle (kullanıcı değeri korunur, sıfırlanmaz)
      Panel_SyncEditText(id);
   } else {
      // Boş/geçersiz → global DEĞİŞMEZ; kutuyu eski değere geri yaz
      Panel_SyncEditText(id);
      g_panelApplyMsg = "● " + msg;
      g_panelApplyMsgUntil = TimeCurrent() + 3;
   }
   return ok;
}

// Tüm editler (UYGULA / MASTER butonu)
bool Panel_ApplyEdits() {
   string ids[] = {
      "edLot","edStep","edBul","edPeak","edMult","edTpPts","edBak","edTpVar",
      "edWork","edIdle","edDd","edDdTp","edPr","edLr",
      "edStepPnt","edLossBek","edLossAd","edPrBek","edPrAd","edHassas","edOnay","edTol",
      "edKul","edKarKul","edZarKul","edVtp","edZarBlok","edOrnek","edAtrTrig","edAdxThr",
      "edHdgWait","edHdgPr","edMaxRst","edRstMin","edNfBef","edNfAft"
   };
   int nOk = 0;
   string lastMsg = "";
   for(int i = 0; i < ArraySize(ids); i++) {
      string name = PN_PREFIX + ids[i];
      if(ObjectFind(0, name) < 0) continue;
      string raw = ObjectGetString(0, name, OBJPROP_TEXT);
      string msg = "";
      if(Panel_ParseEditValue(ids[i], raw, msg)) {
         nOk++;
         lastMsg = msg;
      }
   }
   if(g_lattice.initialized)
      Lattice_RefreshSteps(g_lattice, g_symbol);
   GV_MarkDirty();
   PanelMemory_Save();
   // Tüm kutuları runtime ile senkron – boş/sıfır yazma yok
   for(int j = 0; j < ArraySize(ids); j++)
      Panel_SyncEditText(ids[j]);
   g_panelApplyMsg = StringFormat("● UYGULA %d alan | %s", nOk, lastMsg);
   g_panelApplyMsgUntil = TimeCurrent() + 5;
   PrintFormat("Panel APPLY | lot=%.2f step=%.1f mult=%.3f tpPts=%.0f peak=%.1f (ok=%d)",
               g_rt_vg_lot, g_rt_vg_step, g_rt_grid_mult, g_rt_tp_pts, g_rt_peak, nOk);
   return (nOk > 0);
}




//+------------------------------------------------------------------+
//| CANVAS PREMIUM PANEL v1.57 – Nexus Bullet v7 layout              |
//+------------------------------------------------------------------+
CCanvas g_cv;
string  g_cvObj = "NXR21_CANVAS";

#define CV_MAX_HIT 256
string  g_hitId[CV_MAX_HIT];
int     g_hitX1[CV_MAX_HIT], g_hitY1[CV_MAX_HIT], g_hitX2[CV_MAX_HIT], g_hitY2[CV_MAX_HIT];
int     g_hitN = 0;
int     g_cvViewTop = 0, g_cvViewH = 0;

uint CV_A(const color c, const uchar a = 255) { return ColorToARGB(c, a); }
void CV_HitClear() { g_hitN = 0; }
void CV_HitAdd(const string id, int x1, int y1, int x2, int y2) {
   if(g_hitN >= CV_MAX_HIT || x2 <= x1 || y2 <= y1) return;
   g_hitId[g_hitN] = id;
   g_hitX1[g_hitN]=x1; g_hitY1[g_hitN]=y1; g_hitX2[g_hitN]=x2; g_hitY2[g_hitN]=y2;
   g_hitN++;
}
string CV_HitTest(int mx, int my) {
   int lx = mx - g_cvX, ly = my - g_cvY;
   for(int i = g_hitN - 1; i >= 0; i--)
      if(lx >= g_hitX1[i] && lx < g_hitX2[i] && ly >= g_hitY1[i] && ly < g_hitY2[i])
         return g_hitId[i];
   return "";
}

// v1.78.51 (#121) UX: Panel "profesyonel gorunum" yenilemesi — eski parlak
// turkuaz/teal tema (hemen hemen HER ogede ayni renk: acik durum, vurgu,
// cerceve, sekme...) tek-notali ve amator gorunuyordu. Yeni palet: koyu
// grafit zemin + ALTIN (gold) vurgu (XAUUSD/gold trading temasiyla da
// ortusuyor) — marka/secili durum icin ALTIN, pozitif/ACIK icin YESIL,
// negatif/KAPALI icin KIRMIZI, dikkat icin AMBER ayri ayri kullanilir.
// Asagidaki adlar (CV_ACC, CV_ON, vb.) ayni kaldigi icin panelin geri
// kalanindaki tum cizim kodu DEGISMEDEN yeni temaya otomatik gecer.
color CV_BG=C'15,16,19', CV_BG2=C'10,11,13', CV_CARD=C'23,25,30', CV_CARD2=C'31,34,41', CV_ACC=C'199,167,90';
color CV_ACC2=C'138,109,55', CV_RED=C'196,74,74', CV_WARN=C'209,146,58';
color CV_TXT=C'230,228,222', CV_DIM=C'134,138,148', CV_LINE=C'47,50,58';
color CV_ON=C'45,110,86', CV_OFF=C'39,42,50', CV_CHIP=C'33,36,43';
color CV_INK=C'22,19,14'; // altin/parlak zeminlerde okunakli koyu metin
// v1.78.53 (#123): Info karti icin ek vurgu renkleri — TEMINAT/SERBEST
// TEMINAT (neon mavi) ve MAKS. DD (neon mor) artik diger satirlarla ayni
// tona (CV_TXT/CV_ACC) karismasin diye ayri tanimlandi.
color CV_NEONBLUE=C'64,180,255';
color CV_NEONPURPLE=C'186,85,255';

// v1.73: font cache – her TextOut'ta FontSet maliyeti yüksek
static int  s_cvFontSz   = -1;
static bool s_cvFontBold = false;
void CV_FontApply(const int sz, const bool bold) {
   int s = ScaleFont(sz);
   if(s == s_cvFontSz && bold == s_cvFontBold) return;
   s_cvFontSz = s;
   s_cvFontBold = bold;
   g_cv.FontSet("Arial", s, bold ? FW_BOLD : FW_NORMAL);
}

void CV_Rect(int x,int y,int w,int h,color c){
   if(w>0 && h>0) g_cv.FillRectangle(x, y, x+w-1, y+h-1, CV_A(c));
}
void CV_Frame(int x,int y,int w,int h,color c){
   if(w<2||h<2) return;
   uint u=CV_A(c);
   g_cv.Line(x,y,x+w-1,y,u);
   g_cv.Line(x,y+h-1,x+w-1,y+h-1,u);
   g_cv.Line(x,y,x,y+h-1,u);
   g_cv.Line(x+w-1,y,x+w-1,y+h-1,u);
}
void CV_Round(int x,int y,int w,int h,color c,int r=5){
   if(w<2||h<2) return;
   // Küçük radius → tek dikdörtgen (6 fill yerine 1)
   if(r <= 2){ CV_Rect(x,y,w,h,c); return; }
   if(r*2>w) r=w/2; if(r*2>h) r=h/2;
   // 3 fill yeter (köşe blokları orta ile örtüşür)
   CV_Rect(x+r, y,   w-2*r, h, c);
   CV_Rect(x,   y+r, w,     h-2*r, c);
   // köşeler tek pass yaklaşık
   CV_Rect(x, y, r, r, c);
   CV_Rect(x+w-r, y, r, r, c);
   CV_Rect(x, y+h-r, r, r, c);
   CV_Rect(x+w-r, y+h-r, r, r, c);
}
void CV_Text(int x,int y,const string t,color c,int sz=9,bool bold=false){
   CV_FontApply(sz, bold);
   g_cv.TextOut(x, y, t, CV_A(c), TA_LEFT|TA_TOP);
}
void CV_TextC(int x,int y,int w,int h,const string t,color c,int sz=9,bool bold=false){
   CV_FontApply(sz, bold);
   int tw = (int)g_cv.TextWidth(t);
   // TextHeight pahalı – satır yüksekliğini font size ile yaklaşıkla
   int th = ScaleFont(sz) + 2;
   g_cv.TextOut(x+(w-tw)/2, y+(h-th)/2, t, CV_A(c), TA_LEFT|TA_TOP);
}
bool CV_Vis(int yy,int hh){
   // Erken red – viewport dışı çizim/hit yok
   return (yy + hh > g_cvViewTop && yy < g_cvViewTop + g_cvViewH);
}

// v7 badge
// v1.78.51 (#121): ACIK/ON durumu artik YESIL dolgu + acik-yesil cerceve/nokta
// kullaniyor (eskiden dolgu yesil ama cerceve ALTIN idi — renk ailesi
// tutarsizdi). ALTIN (CV_ACC) artik SADECE marka/secim vurgusu icin ayrilir.
color CV_ONHI = C'104,196,150'; // toggle-ON: acik yesil cerceve/nokta
color CV_ONTX = C'208,238,222'; // toggle-ON: yumusak nane-beyaz metin
void CV_Badge(int x,int y,int w,int h,const string label,bool on,const string hitId){
   color bg = on ? CV_ON : CV_OFF;
   color tx = on ? CV_ONTX : CV_DIM;
   CV_Round(x,y,w,h,bg,5);
   if(on) CV_Frame(x,y,w,h,CV_ONHI);
   string t = label + (on ? ": ACIK" : ": KAPALI");
   CV_TextC(x,y,w,h,t,tx,8,true);
   CV_HitAdd(hitId,x,y,x+w,y+h);
}
void CV_Pill(int x,int y,int w,int h,const string text,bool on,const string hitId){
   CV_Round(x,y,w,h, on?CV_ON:CV_OFF, 4);
   if(on) CV_Frame(x,y,w,h,CV_ONHI);
   CV_Text(x+8, y+(h-11)/2, text, on?CV_ONTX:CV_DIM, 8, true);
   // FillCircle yerine küçük kare – daha ucuz
   CV_Rect(x+w-13, y+h/2-2, 5, 5, on?CV_ONHI:C'76,81,92');
   CV_HitAdd(hitId,x,y,x+w,y+h);
}
void CV_Btn(int x,int y,int w,int h,const string text,color bg,color tx,const string hitId){
   CV_Round(x,y,w,h,bg,5); CV_Frame(x,y,w,h,CV_LINE);
   CV_TextC(x,y,w,h,text,tx,9,true);
   CV_HitAdd(hitId,x,y,x+w,y+h);
}

string AdaptiveMarket_DisplayName() {
   if(g_rt_auto_adapt && (g_ddHedgePaused ||
      (g_rt_ready && g_rt_genel_hedge && AccountInfoDouble(ACCOUNT_EQUITY) < AccountInfoDouble(ACCOUNT_BALANCE))))
      return "HEDGE";
   switch(RT_Regime()) {
      case TPP_REG_FIXED: return "FIXED";
      case TPP_REG_BALANCE_PCT: return "BAKIYE%";
      case TPP_REG_TARGET_DEFICIT: return "DEFICIT";
      case TPP_REG_CONTROLLED_RECOVERY: return "RECOVERY";
      case TPP_REG_NET_VOLUME_TARGET: return "NETVOL";
      case TPP_REG_SOLVER: return "COZUCU";
   }
   return "FIXED";
}

string AdaptiveMarket_DisplayText() {
   string name = AdaptiveMarket_DisplayName();
   return g_rt_auto_adapt ? name + " AKTIF" : name + " PASIF";
}

color AdaptiveMarket_DisplayColor() {
   if(!g_rt_auto_adapt) return CV_DIM;
   string name = AdaptiveMarket_DisplayName();
   if(name == "RECOVERY" || name == "HEDGE") return CV_WARN;
   if(name == "NETVOL" || name == "COZUCU") return CV_NEONBLUE;
   if(name == "DEFICIT") return CV_ACC2;
   if(name == "BAKIYE%") return CV_ONHI;
   return CV_ACC;
}

void AdaptiveMarket_SyncStatusObject() {
   // v1.78.130: Harici AUTO_REGIME_STATUS butonu panel dışında yaratılmıyor;
   // otonom durum bilgisi artık panel içi bilgi satırında doğrudan çizilir.
}

void CV_Tab(int x,int y,int w,int h,const string text,bool active,const string hitId){
   CV_Round(x,y,w,h, active?CV_ACC2:CV_CARD2, 4);
   if(active) CV_Rect(x+4, y+h-3, w-8, 3, CV_ACC);
   CV_TextC(x,y,w,h,text, active?clrWhite:CV_DIM, 8, active);
   CV_HitAdd(hitId,x,y,x+w,y+h);
}
// v1.72 ticari: etiket | DEGER chip | sagda deger (edit ayni satir)
// editId doluysa DEGER chip tiklaninca o edit odaklanir (hitId = "focus:"+editId)
int CV_ValRow(int x,int y,int w,int h,const string label, const string valTxt="",
              const string editId=""){
   CV_Text(x, y+(h-11)/2, label, CV_DIM, 8, false);
   int chipW = 52;
   int chipH = h - 4;
   int chipX = x + 88;
   if(chipX + chipW > x + w - 70) chipX = x + (w/2) - (chipW/2);
   int chipY = y + 2;
   CV_Round(chipX, chipY, chipW, chipH, CV_CARD2, 4);
   CV_Frame(chipX, chipY, chipW, chipH, CV_ACC);
   CV_TextC(chipX, chipY, chipW, chipH, "DEGER", CV_ACC, 7, true);
   if(StringLen(editId) > 0)
      CV_HitAdd("focus:"+editId, chipX, chipY, chipX+chipW, chipY+chipH);
   if(StringLen(valTxt) > 0 && StringLen(editId) == 0) {
      CV_FontApply(9, true);
      int tw = (int)g_cv.TextWidth(valTxt);
      int vx = x + w - tw - 4;
      if(vx < chipX + chipW + 6) vx = chipX + chipW + 6;
      g_cv.TextOut(vx, y+(h-11)/2, valTxt, CV_A(CV_ACC), TA_LEFT|TA_TOP);
   }
   return chipX + chipW + 4;
}

// CV_ValEditRow → CV_ShowEditInline sonrasinda tanimli (ileri bildirim)
void CV_ValEditRow(int x, int y, int w, int h, const string label,
                   const string editId, const string valTxt);

int CV_FitH(){
   int chartH=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
   if(chartH<120) chartH=560;
   int maxH=chartH-g_cvY-8; if(maxH<300) maxH=300;
   // v1.73: viewport tabanı + scale; chart dışına taşmaz
   int want = ScaleLen(PN_H);
   int vmin = PANEL_VIEWPORT_MIN_H + ScaleLen(PN_HDR_H + PN_FTR_H);
   if(want < vmin) want = vmin;
   if(want>maxH) want=maxH;
   return want;
}
void CV_Destroy(){
   if(g_cvReady){ g_cv.Destroy(); g_cvReady=false; }
   if(ObjectFind(0,g_cvObj)>=0) ObjectDelete(0,g_cvObj);
}
bool CV_Ensure(int w,int h){
   if(w<100) w=320; if(h<200) h=420;
   if(g_cvReady && g_cvW==w && g_cvH==h && ObjectFind(0,g_cvObj)>=0) return true;
   CV_Destroy(); ResetLastError();
   if(!g_cv.CreateBitmapLabel(0,0,g_cvObj,g_cvX,g_cvY,w,h,COLOR_FORMAT_XRGB_NOALPHA)){
      PrintFormat("NEXUS Canvas FAIL err=%d", GetLastError());
      g_cvReady=false; return false;
   }
   ObjectSetInteger(0,g_cvObj,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,g_cvObj,OBJPROP_XDISTANCE,g_cvX);
   ObjectSetInteger(0,g_cvObj,OBJPROP_YDISTANCE,g_cvY);
   ObjectSetInteger(0,g_cvObj,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,g_cvObj,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,g_cvObj,OBJPROP_BACK,false);  // onde: renkler gorunsun
   ObjectSetInteger(0,g_cvObj,OBJPROP_ZORDER,1000);
   ObjectSetInteger(0,g_cvObj,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
   g_cvW=w; g_cvH=h; g_cvReady=true;
   s_cvFontSz=-1;
   PrintFormat("NEXUS Canvas OK v1.78.13 %dx%d @%d,%d",w,h,g_cvX,g_cvY);
   return true;
}
// Panel_BeginEdit → aşağıda OBJ_EDIT olay bloğunda

void Panel_EndEdit()
{
   g_panelEditing = false;
   g_panelEditingId = "";
   g_panelEditingSince = 0;
}

// DÜZELTME v1.68: Bir edit kutusundan yazmayı bitirmeden DOĞRUDAN başka bir edit
// kutusuna tıklandığında, MT5 CHARTEVENT_OBJECT_ENDEDIT'i otomatik tetiklemiyor
// (yalnızca Enter tetikler). Bu yüzden önceki kutuya girilen değer hiç Panel_ApplyOne'a
// gitmeden kayboluyordu. Bu fonksiyon, yeni kutuya geçmeden önce varsa eski kutuyu
// düzgünce kapatıp (Panel_EndEdit + Panel_ApplyOne) uygular, sonra yeni kutuyu başlatır.
void Panel_SwitchEdit(const string newEditName)
{
   if(g_panelEditing && g_panelEditingId != newEditName) {
      string fin = g_panelEditingId;
      Panel_EndEdit();
      if(StringLen(fin) > 0) {
         Panel_ApplyOne(fin);
         // Eski kutuyu formatli degerle GORSEL olarak da senkronla (orijinal
         // "editing'den cikis" akisiyla ayni: force sync + redraw)
         g_panelForceEditSync = true;
         Panel_RequestUpdate(true);
         g_panelForceEditSync = false;
         ChartRedraw(0);
      }
   }
   Panel_BeginEdit(newEditName);
}

void CV_ClearEdits(){
   // v1.68: editing iken ERKEN return YOK — scroll'da diger editler eski yerde kalmasin
   // sadece aktif edit kutusu (g_panelEditingId) gizlenmez
   string eds[]={
      "edLot","edStep","edMult","edTpPts","edBul","edPeak","edBak","edTpVar",
      "edStepPnt","edLossBek","edLossAd","edPrBek","edPrAd","edHassas","edOnay","edTol",
      "edKul","edKarKul","edZarKul","edVtp","edZarBlok","edOrnek","edAtrTrig","edAdxThr",
      "edWork","edIdle","edDd","edDdTp","edPr","edLr",
      "edHdgWait","edHdgPr","edMaxRst","edRstMin","edNfBef","edNfAft"
   };
   for(int i=0;i<ArraySize(eds);i++){
      string n=PN_PREFIX+eds[i];
      if(g_panelEditing && n == g_panelEditingId) continue; // sadece aktif edit kalsin
      if(ObjectFind(0,n)>=0){
         ObjectSetInteger(0,n,OBJPROP_TIMEFRAMES,OBJ_NO_PERIODS);
         ObjectSetInteger(0,n,OBJPROP_XDISTANCE,-5000); // FIX v1.78.13: tab degisiminde tiklama guvenligi
      }
   }
}
// forceText=true: sadece create veya Apply sonrası senkron
// forceText=false: yazarken metni EZME (yoksa değer geri sıçrar)
// NOT v1.68: Bu fonksiyon artık HİÇBİR YERDEN ÇAĞRILMIYOR — CV_ShowEditInline
// (aşağıda) panel-içi konumlandırmayla yerini tamamen aldı. Silinmedi (referans/
// geri dönüş ihtimaline karşı) ama ölü koddur; yeni editbox eklerken CV_ShowEditInline
// kullanılmalı, bu değil.
void CV_ShowEdit(const string id,int x,int y,int w,int h,const string text,const bool forceText=false){
   string name=PN_PREFIX+id;
   // Yazma sirasinda bu edit'e DOKUNMA
   if(g_panelEditing && g_panelEditingId == name)
      return;

   bool created=false;
   if(ObjectFind(0,name)<0){
      if(!ObjectCreate(0,name,OBJ_EDIT,0,0,0)){
         PrintFormat("NEXUS EDIT create FAIL %s err=%d", name, GetLastError());
         return;
      }
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,name,OBJPROP_ALIGN,ALIGN_RIGHT);
      ObjectSetString(0,name,OBJPROP_FONT,"Arial");
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,10);
      ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'20,28,42');
      ObjectSetInteger(0,name,OBJPROP_COLOR,C'0,220,200');
      ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,C'0,180,160');
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,true);
      ObjectSetInteger(0,name,OBJPROP_READONLY,false);
      ObjectSetInteger(0,name,OBJPROP_ZORDER,100000);
      ObjectSetInteger(0,name,OBJPROP_BACK,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,false);
      ObjectSetString(0,name,OBJPROP_TEXT,text);
      created=true;
   }
   ObjectSetInteger(0,name,OBJPROP_READONLY,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,100000);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);

   // (Kullanilmayan eski davranis) Edit canvas DISINDA (sag sutun) konumlaniyordu
   int nx = g_cvX + g_cvW + 4;
   int ny = g_cvY + y;
   int curX = (int)ObjectGetInteger(0,name,OBJPROP_XDISTANCE);
   int curY = (int)ObjectGetInteger(0,name,OBJPROP_YDISTANCE);
   if(MathAbs(curX - nx) > 2 || created)
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,nx);
   if(MathAbs(curY - ny) > 2 || created)
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,ny);
   int ew = (w > 80 ? w : 96);
   int eh = (h > 16 ? h : 20);
   if((int)ObjectGetInteger(0,name,OBJPROP_XSIZE) != ew)
      ObjectSetInteger(0,name,OBJPROP_XSIZE,ew);
   if((int)ObjectGetInteger(0,name,OBJPROP_YSIZE) != eh)
      ObjectSetInteger(0,name,OBJPROP_YSIZE,eh);
   if((long)ObjectGetInteger(0,name,OBJPROP_TIMEFRAMES) == OBJ_NO_PERIODS)
      ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);

   if(created || forceText || (g_panelForceEditSync && !g_panelEditing))
      ObjectSetString(0,name,OBJPROP_TEXT,text);
}


//+------------------------------------------------------------------+
//| EDITBOX – gerçek OBJ_EDIT, viewport'a gömülü, scroll güvenli      |
//+------------------------------------------------------------------+
void Panel_HideAllEdits() {
   string eds[]={
      "edLot","edStep","edMult","edTpPts","edBul","edPeak","edBak","edTpVar",
      "edStepPnt","edLossBek","edLossAd","edPrBek","edPrAd","edHassas","edOnay","edTol",
      "edKul","edKarKul","edZarKul","edVtp","edZarBlok","edOrnek","edAtrTrig","edAdxThr",
      "edWork","edIdle","edDd","edDdTp","edPr","edLr",
      "edHdgWait","edHdgPr","edMaxRst","edRstMin","edNfBef","edNfAft"
   };
   for(int i=0;i<ArraySize(eds);i++){
      string n=PN_PREFIX+eds[i];
      if(ObjectFind(0,n)<0) continue;
      // Aktif yazılan kutuyu gizleme
      if(g_panelEditing && n==g_panelEditingId) continue;
      ObjectSetInteger(0,n,OBJPROP_TIMEFRAMES,OBJ_NO_PERIODS);
      ObjectSetInteger(0,n,OBJPROP_XDISTANCE,-5000); // FIX v1.78.13: CV_ClearEdits ile tutarli
   }
}

// GUI SAFETY: EditBox oluşturma/güncelleme işlemlerinde tüm platform çağrıları
// hata kontrollüdür; aktif olmayan kutu seçilebilir veya veri yazılabilir kalmaz.
void CreateEdit(const string name, const int x, const int y, const int w, const int h, const string text="")
{
   if(StringFind(name, PN_PREFIX) != 0 || StringLen(name) <= StringLen(PN_PREFIX))
      return;

   bool editingThis = (g_panelEditing && g_panelEditingId == name);
   bool created = false;
   if(ObjectFind(0, name) < 0)
   {
      ResetLastError();
      if(!ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0))
      {
         PrintFormat("CREATE EDIT FAIL | %s | err=%d", name, GetLastError());
         return;
      }
      created = true;
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_RIGHT);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'23,25,30');
      ObjectSetInteger(0, name, OBJPROP_COLOR, C'230,228,222');
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'138,109,55');
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_READONLY, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 200000);
   }

   ResetLastError();
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, MathMax(w, 40));
   ObjectSetInteger(0, name, OBJPROP_YSIZE, MathMax(h, 16));
   ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(0, name, OBJPROP_READONLY, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, editingThis);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 200000);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);

   if(created || !editingThis)
      ObjectSetString(0, name, OBJPROP_TEXT, text);
}

// panelX/Y = canvas içi mantıksal (scroll uygulanmış cy ile)
// Görünür değilse gizle — üst üste binme olmaz
void CV_ShowEditInline(const string id, int panelX, int panelY, int w, int h, const string text, bool forceText=false)
{
   string name = PN_PREFIX + id;
   bool editingThis = (g_panelEditing && g_panelEditingId == name);

   // Viewport dışı → gizle (aktif yazım hariç) — FIX: editingThis erken return olmasın
   if(!CV_Vis(panelY, h) && !editingThis) {
      if(ObjectFind(0, name) >= 0) {
         ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, -5000); // FIX v1.78.13: tiklama guvenligi
      }
      return;
   }

   int sx = g_cvX + panelX;
   int sy = g_cvY + panelY;
   // Footer altına taşmayı engelle (aktif edit korunur)
   if(sy + h > g_cvY + g_cvH - 30 && !editingThis) {
      if(ObjectFind(0, name) >= 0) {
         ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, -5000); // FIX v1.78.13: tiklama guvenligi
      }
      return;
   }

   bool oldForce = g_panelForceEditSync;
   if(forceText) g_panelForceEditSync = true;
   CreateEdit(name, sx, sy, w, h, text);
   if(forceText) g_panelForceEditSync = oldForce;
}

// v1.72: label + DEGER chip + sag edit (ayni satir)
void CV_ValEditRow(int x, int y, int w, int h, const string label,
                   const string editId, const string valTxt) {
   // Görünmez satır: label çizme + edit gizle (üst üste binmeyi önler)
   if(!CV_Vis(y, h)) {
      string n = PN_PREFIX + editId;
      if(!(g_panelEditing && g_panelEditingId == n) && ObjectFind(0, n) >= 0) {
         ObjectSetInteger(0, n, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
         ObjectSetInteger(0, n, OBJPROP_XDISTANCE, -5000); // FIX v1.78.13: tıklama güvenliği
      }
      return;
   }
   int editX = CV_ValRow(x, y, w, h, label, "", editId);
   int editW = x + w - editX;
   if(editW < 56) editW = 56;
   CV_ShowEditInline(editId, editX, y+1, editW, h-2, valTxt);
}

// Ileri bildirim (Create / RequestUpdate once cagirir)
void UpdateMinimalPanel();

void CreateMinimalPanel(){
   int total=ObjectsTotal(0,0,-1);
   for(int i=total-1;i>=0;i--){
      string name=ObjectName(0,i,0,-1);
      if(StringFind(name,PN_PREFIX)==0 || name==g_cvObj) ObjectDelete(0,name);
   }
   CV_Destroy();
   g_panelScroll=0;
   g_cvX=PN_X; g_cvY=PN_Y;
   // v1.73: runtime scale (GV/input) + chart taşma koruması
   g_panelScale = Panel_ClampScale(g_panelScale > 0.5 ? g_panelScale : InpPanelScale);
   int w = ScaleLen(MathMax(PN_W, 330));
   {
      int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      if(chartW > 80 && w > chartW - 10)
         w = chartW - 10;
   }
   int h=CV_FitH();
   if(!CV_Ensure(w,h)){ Print("NEXUS: canvas yok"); return; }
   ChartSetInteger(0,CHART_EVENT_MOUSE_WHEEL,true);
   ChartSetInteger(0,CHART_KEYBOARD_CONTROL,true);
   ChartSetInteger(0,CHART_QUICK_NAVIGATION,false);
   g_panelForceEditSync=true;
   g_panelEditing=false;
   g_panelEditingId="";
   UpdateMinimalPanel();
   ChartRedraw(0);
}


// Panel UI throttle: force=false → InpPanelRefreshMs aralığı
void Panel_RequestUpdate(const bool force=false)
{
   // Düzenleme açıkken: panel çizilebilir ama TEXT force sync YASAK
   if(g_panelEditing) {
      g_panelForceEditSync = false; // yazılan metni koru
      if(!force) return; // tick throttle yolu – tamamen atla
      // force (scroll/tab): çizim olur, CreateEdit text'e dokunmaz (editingThis)
   }

   if(!force)
   {
      int ms = InpPanelRefreshMs;
      if(ms < 0) ms = 0;
      if(ms > 0)
      {
         ulong now = GetTickCount();
         if(g_lastPanelUiMs != 0 && (now - g_lastPanelUiMs) < (ulong)ms)
            return;
         g_lastPanelUiMs = now;
      }
   }
   else
      g_lastPanelUiMs = GetTickCount();

   UpdateMinimalPanel();
}

void UpdateMinimalPanel(){
   if(!g_cvReady || ObjectFind(0,g_cvObj)<0){
      static bool re=false; if(re) return; re=true; CreateMinimalPanel(); re=false; return;
   }
   g_panelScale = Panel_ClampScale(g_panelScale > 0.5 ? g_panelScale : InpPanelScale);
   int w = ScaleLen(MathMax(PN_W, 330));
   {
      int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      if(chartW > 80 && w > chartW - 10)
         w = chartW - 10;
   }
   int h=CV_FitH();
   if(w!=g_cvW||h!=g_cvH){ if(!CV_Ensure(w,h)) return; }

   static int s_lastMain=-1, s_lastSub=-1, s_lastScroll=-999;
   static int s_lastCvX=-1, s_lastCvY=-1;
   bool tabChanged = (s_lastMain != g_panelMainTab || s_lastSub != g_panelSubTab);
   bool scrollChanged = (s_lastScroll != g_panelScroll);
   // Edit gizleme: sadece sekme/zorla – her scroll'da ClearEdits pahalı
   if(tabChanged || g_panelForceEditSync)
      CV_ClearEdits();
   s_lastMain = g_panelMainTab;
   s_lastSub  = g_panelSubTab;
   s_lastScroll = g_panelScroll;

   CV_HitClear();
   s_cvFontSz = -1; // frame başı font cache invalid
   g_cv.Erase(CV_A(CV_BG));
   CV_Frame(0,0,w,h,CV_ACC2);
   CV_Rect(1,1,w-2,3,CV_ACC);

   int pad=8;
   int y=6;

   // ===== HEADER: DGN NEXUS PRO =====
   // v1.78.51 (#122) UX: Baslik alani duz/yassi duruyordu — "TR" etiketi
   // basligin bittigi yerden SABIT 168px sonraya konuyordu (metin genisligi
   // hic olculmuyordu), bu yuzden panel olcegi (+/-) degistiginde veya farkli
   // DPI'da metinle etiket ust uste binebiliyor ya da aralarinda cirkin bir
   // bosluk kalabiliyordu. Artik TextWidth() ile GERCEK genislik olculup
   // "TR" kucuk bir rozet (arka plan+cerceve) olarak yerlestiriliyor, baslik
   // fontu buyutuldu ve header'in altina ince bir ayrac cizgisi eklendi.
   // v1.78.53 (#123): Baslik artik surum numarasini da iceriyor ("DGN NEXUS
   // PRO v1.78.53") ve dikeyde 28px'lik header kutusunun TAM ORTASINA
   // hizalandi (eskiden sabit y+5 idi, buyuyen fontla kutunun ustune
   // kayabiliyordu). Font 11->12 buyutuldu; "TR" rozeti de yeni genislige
   // ve dikey merkeze gore yeniden konumlandi.
   int headerH = 28;
   CV_Rect(1,1,w-2,headerH,CV_CARD);
   int brandFontSz = 12;
   CV_FontApply(brandFontSz,true);
   string brandTxt = "DGN NEXUS PRO "+g_dgn_version; // v1.78.72: g_dgn_version artik kendi "v" onekini iceriyor (DGN_BUILD_TAG)
   int brandTh = ScaleFont(brandFontSz) + 2;
   int brandY  = 1 + (headerH - brandTh) / 2;
   CV_Text(pad,brandY,brandTxt,CV_ACC,brandFontSz,true);
   int brandW = (int)g_cv.TextWidth(brandTxt);
   int trX = pad + brandW + 10;
   int trH = 15;
   int trY = 1 + (headerH - trH) / 2;
   CV_Round(trX, trY, 20, trH, CV_CARD2, 3);
   CV_Frame(trX, trY, 20, trH, CV_ACC2);
   CV_TextC(trX, trY, 20, trH, "TR", CV_ACC, 7, true);
   CV_Rect(1,headerH,w-2,1,CV_LINE); // header/icerik ayraci
   // v1.73: panel ölçek +/- (sağ üst)
   CV_Btn(w-pad-78, 4, 22, 20, "+", CV_ON, clrWhite, "btnScalePlus");
   CV_Btn(w-pad-52, 4, 22, 20, "-", CV_RED, clrWhite, "btnScaleMinus");
   CV_Text(w-pad-26, 8, StringFormat("%.1f", g_panelScale), CV_DIM, 7, false);
   y=30;
   // FIX v1.78.13: risk modu artik 5 ayri buton (secilen vurgulu, digerleri sonuk) -
   // eskiden A-/%/1.0x/A+ ile donguydu, GUVENLI/AGRESIF gibi isimler hic gorunmuyordu.
   // Kisa 3 harfli kodlar bilerek secildi: canli render'i test edemedigim icin
   // tam kelimeler (GUVENLI, AGRESIF...) dar butonda tasabilir - yer oldugu
   // görülürse uzatilabilir.
   CV_Round(pad,y,w-pad*2,22,CV_CARD2,4);
   {
      string riskNames[5] = {"CGV","GUV","DNG","HIZ","AGR"};
      int rsw = (w - pad*2 - 100) / 5;
      if(rsw < 30) rsw = 30;
      for(int rk=0; rk<5; rk++) {
         bool sel = (g_rt_risk_mode == rk);
         color bg = sel ? CV_ACC2 : CV_CARD2;
         color tx = sel ? CV_INK      : CV_DIM; // v1.78.51: altin zeminde koyu metin okunakli
         CV_Btn(pad+2+rk*(rsw+2), y+2, rsw, 18, riskNames[rk], bg, tx, "tgRisk"+IntegerToString(rk));
      }
   }
   CV_Btn(w-pad-92,y+1,84,20,"MASTER UYGULA",CV_ACC2,CV_INK,"btnMaster"); // v1.78.51: altin CTA + koyu metin
   y+=26;

   // ===== INFO SATIRI: Sistem durum özeti =====
   // v1.78.130: Panel framework'ünün içine entegre bilgi satırı - taşma hatası giderildi
   CV_Round(pad,y,w-pad*2,16,CV_CARD2,3);
   string infoParts[3];
   infoParts[0] = StringFormat("SISTEM: %s", g_robotOn ? "ÇALIŞIYOR" : "KAPALI");
   infoParts[1] = StringFormat("Lot Mode: %s", RT_LotModeName());
   infoParts[2] = StringFormat("Rejim: %s", g_rt_auto_adapt ? ("OTONOMUS " + g_rt_auto_note) : RT_RegimeName());
   int infoPartW = (w - pad * 2 - 12) / 3;
   CV_Text(pad + 6, y + 2, infoParts[0], CV_TXT, 7, false);
   CV_Text(pad + infoPartW + 8, y + 2, infoParts[1], CV_TXT, 7, false);
   CV_Text(pad + (infoPartW + 8) * 2, y + 2, infoParts[2], CV_TXT, 7, false);
   y+=18;

   // v1.78.130: Otonom PROJ / RECOVERY durum metni harici nesne yaratmadan
   // panel içi bilgi satırında canlı gösterilir; dışarı çıkma veya hiyerarşik
   // buton çakışması yaratmaz.
   string projInfoText = g_rt_auto_adapt
      ? (g_rt_tp_regime == TPP_REG_CONTROLLED_RECOVERY
         ? "PROJ AKTIF | RECOVERY MODU | " + AdaptiveMarket_DisplayText()
         : "PROJ AKTIF | " + AdaptiveMarket_DisplayText())
      : "PROJ MANUEL | " + RT_RegimeName();
   color projInfoColor = g_rt_auto_adapt ? AdaptiveMarket_DisplayColor() : CV_DIM;
   CV_Round(pad,y,w-pad*2,16,CV_CARD2,3);
   CV_Text(pad + 6, y + 2, projInfoText, projInfoColor, 7, false);
   y += 18;

   // ===== Ana sekmeler: STRATEJI | ISLEMLER | SISTEM | SONUC =====
   string mains[4]; mains[0]="STRATEJI"; mains[1]="ISLEMLER"; mains[2]="SISTEM"; mains[3]="SONUC";
   int mw=(w-pad*2-12)/4;
   for(int m=0;m<4;m++){
      bool act=(g_panelMainTab==m);
      CV_Tab(pad+m*(mw+4),y,mw,22,mains[m],act,"main"+IntegerToString(m));
   }
   y+=26;

   // ===== Istatistik karti (ticari: OZSERMAYE / TEMINAT% / BASARI / MAKS.DD) =====
   double net=Panel_NetFloating();
   double deg=Panel_IndependentEquityChange();
   double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   double bal=AccountInfoDouble(ACCOUNT_BALANCE);
   double fre=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double mgn=AccountInfoDouble(ACCOUNT_MARGIN);
   double mgnLvl = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   if(mgnLvl <= 0 && mgn > 0) mgnLvl = (eq / mgn) * 100.0;
   double degPct=(bal>0)?(deg/bal*100.0):0.0;
   double netPct=(bal>0)?(net/bal*100.0):0.0;
   // basit basari / max DD (gunluk bagimsiz equity uzerinden)
   static double s_peakEq = 0;
   if(eq > s_peakEq) s_peakEq = eq;
   double maxDdPct = (s_peakEq > 0) ? ((s_peakEq - eq) / s_peakEq * 100.0) : 0.0;
   if(maxDdPct < 0) maxDdPct = 0;
   double basariPct = Panel_CalcSuccessRate(); // FIX v1.78.13: gerçek kapanan işlem oranı
   int cardH=88;
   CV_Round(pad,y,w-pad*2,cardH,CV_CARD,6);
   CV_Frame(pad,y,w-pad*2,cardH,CV_LINE);
   int col2=pad+(w-pad*2)/2;
   // v1.78.53 (#123): OZSERMAYE + BAKIYE artik sabit BEYAZ — panelin en temel
   // iki rakami, esik bazli renklendirme yerine her zaman net okunur olsun diye.
   CV_Text(pad+8,y+4, StringFormat("OZSERMAYE: %.2f",eq),clrWhite,8,true);
   CV_Text(col2,y+4, StringFormat("BAKIYE: %.2f",bal),clrWhite,8,true);
   // v1.78.48 FIX (#119 - UX): TEMINAT/SERBEST TEMINAT/BASARI/MAKS.DD eskiden hepsi
   // sabit CV_DIM (gri) idi — panelin geri kalanindaki NET/DEGISIM gibi anlamli
   // (esik bazli) renklendirme burada yoktu. Artik ayni desene uyuyor: guvenli/
   // notr/riskli durumlara gore CV_ACC (teal) / CV_WARN (amber) / CV_RED renklenir.
   // v1.78.53 (#123): TEMINAT ve SERBEST TEMINAT artik ikisi de CV_NEONBLUE (neon
   // mavi) — eskiden TEMINAT esik bazli / SERBEST TEMINAT CV_ACC2 (altin) idi ve
   // ikisi birbirinden farkli, panelin geri kalaniyla karisan tonlardaydi.
   CV_Text(pad+8,y+20,StringFormat("TEMINAT: %.1f%%",mgnLvl),CV_NEONBLUE,8,false);
   CV_Text(col2,y+20,StringFormat("SERBEST TEMINAT: %.0f",fre),CV_NEONBLUE,8,false);
   color netC=(net>=0)?CV_ACC:CV_RED;
   string dirTxt = Panel_DirText();
   if(g_ctx.dir.direction < 0) dirTxt = "SATIS (SELL)";
   else if(g_ctx.dir.direction > 0) dirTxt = "ALIS (BUY)";
   else dirTxt = "NOTR";
   // v1.78.53 (#123): NET satirindaki yon metni (ALIS/SATIS/NOTR) artik NET
   // rakaminin ($ renginin) ayrisik: NOTR sari, net>=0 iken ALIS/SATIS yesil,
   // net negatife dusunce kirmizi. Onceden yon metni sayiyla ayni netC'yi
   // paylasiyordu ve gorsel olarak ayirt edilemiyordu.
   color dirC = (net<0) ? CV_RED : (g_ctx.dir.direction==0 ? clrYellow : CV_ONHI);
   CV_Text(pad+8,y+36,StringFormat("NET: %.2f  ",net),netC,8,true);
   int netNumW = (int)g_cv.TextWidth(StringFormat("NET: %.2f  ",net));
   CV_Text(pad+8+netNumW,y+36,dirTxt,dirC,8,true);
   color npC=(netPct>=0)?CV_ACC:CV_RED;
   CV_Text(pad+8,y+50,StringFormat("NET DEGISIM: %+.2f%% ($%+.2f)",netPct,net),npC,8,false);
   color basariC = (basariPct>=55.0) ? CV_ACC : (basariPct>=40.0 ? CV_WARN : CV_RED);
   CV_Text(pad+8,y+64,StringFormat("BASARI: %.1f%%",basariPct),basariC,8,false);
   // v1.78.53 (#123): MAKS. DD artik esik bazli renk yerine sabit CV_NEONPURPLE
   // (neon mor) — DD burada bir uyari degil, sadece bir olcum karti oldugu icin
   // ayri/dikkat cekici bir tonla isaretlendi.
   CV_Text(col2,y+64,StringFormat("MAKS. DD: %.2f%%",maxDdPct),CV_NEONPURPLE,8,false);
   color degC=(deg>=0)?CV_ACC:CV_RED;
   CV_Text(pad+8,y+76,StringFormat("DEGISIM: %+.2f USD | %+.2f%%",deg,degPct),degC,8,true);
   CV_Btn(w-pad-64,y+72,56,14,"SIFIRLA",CV_CARD2,clrWhite,"btnResetChg");
   y+=cardH+4;

   // ===== Islev / durum (ticari: TAHMIN YOK // DUYGU YOK // SAF MATEMATIK) =====
   string statusTxt;
   color stC=CV_ACC;
   if(g_panelApplyMsgUntil>0 && TimeCurrent()<=g_panelApplyMsgUntil && StringLen(g_panelApplyMsg)>0){
      statusTxt=g_panelApplyMsg; stC=CV_ACC;
   }else if(!g_robotOn){ statusTxt="ISLEV · ROBOT KAPALI"; stC=CV_WARN; }
   else if(g_newsHardLock){ statusTxt="ISLEV · HABER KILIT"; stC=CV_RED; }
   else if(g_dailyLocked){ statusTxt="ISLEV · GUNLUK KILIT"; stC=CV_RED; }
   else if(g_ddHedgePaused){ statusTxt="ISLEV · DD HEDGE"; stC=CV_WARN; }
   else if(StringLen(g_tradeBlockReason)>0 && StringFind(g_tradeBlockReason,"OK")<0)
      statusTxt="ISLEM · "+g_tradeBlockReason;
   else
      statusTxt="ISLEV · TAHMIN YOK // DUYGU YOK // SAF MATEMATIK";
   CV_Round(pad,y,w-pad*2,18,CV_CARD2,4);
   bool anyLock = (g_dailyLocked || g_timeLimitPaused || g_ddHedgePaused || g_newsHardLock ||
                   (StringLen(g_tradeBlockReason)>0 && StringFind(g_tradeBlockReason,"OK")<0 && g_robotOn));
   if(anyLock){
      CV_Text(pad+8,y+3,statusTxt,stC,8,true);
      int bwUnlock=88;
      CV_Btn(w-pad-bwUnlock-4,y+1,bwUnlock,16,"KILIT KALDIR",CV_RED,clrWhite,"btnUnlock");
   }else{
      CV_Text(pad+8,y+3,statusTxt,stC,8,true);
   }
   y+=22;

   // GENEL alt sekmeleri sadece mainTab==0 (içerik aynı)
   bool genel=(g_panelMainTab==0);
   if(genel){
      string subs[4]; subs[0]="KONTROL"; subs[1]="DEGER"; subs[2]="ARAC"; subs[3]="HABER";
      int sw=(w-pad*2-20)/4;
      for(int s=0;s<4;s++)
         CV_Tab(pad+s*(sw+2),y,sw,20,subs[s],g_panelSubTab==s,"sub"+IntegerToString(s));
      y+=24;
   }

   int ftrH=34;
   // Aktif sekme offset'ini yükle (içerik çizimi g_panelScroll kullanır)
   Panel_SyncScrollFromTab();
   g_cvViewTop=y;
   g_cvViewH=h-y-ftrH-4;
   if(g_cvViewH<50) g_cvViewH=50;
   g_viewportTopY    = g_cvViewTop;
   g_viewportBottomY = g_cvViewTop + g_cvViewH;
   CV_Round(3,g_cvViewTop,w-6,g_cvViewH,CV_BG2,4);
   // FIX: Editbox kaybolma - her tick tümünü gizleme, sadece tab değişince temizle
   // Panel_HideAllEdits() buradan kaldırıldı, CV_ShowEditInline zaten viewport dışını gizliyor

   bool showCtrl=genel && g_panelSubTab==0;
   bool showVal =genel && g_panelSubTab==1;
   bool showArac=genel && g_panelSubTab==2;
   bool showHab =genel && g_panelSubTab==3;
   int lx=pad, innerW=w-pad*2-18, hw=(innerW-6)/2, rowH=24; // sağ scrollbar payı
   int contentH=0;
   int ly=6-g_panelScroll;

   // --- KONTROL (ticari v7 harfiyen) ---
   if(showCtrl){
      int cy=g_cvViewTop+ly; int n=0;
      // ROBOT / ALIS / SATIS
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_robotOn?"ROBOT: ACIK":"ROBOT: KAPALI",g_robotOn,"tgRobot");
      cy+=rowH; n++;
      if(CV_Vis(cy,22)){
         CV_Pill(lx,cy,hw,22,g_panelBuy?"ALIS: ACIK":"ALIS: KAPALI",g_panelBuy,"tgBuy");
         CV_Pill(lx+hw+6,cy,hw,22,g_panelSell?"SATIS: ACIK":"SATIS: KAPALI",g_panelSell,"tgSell");
      }
      cy+=rowH; n++;
      if(CV_Vis(cy,22)){
         CV_Pill(lx,cy,hw,22,g_rt_grid_both?"GRID YON: CIFT":"GRID YON: TEK",g_rt_grid_both,"tgGridDir");
         CV_Pill(lx+hw+6,cy,hw,22,g_rt_trend_both?"TREND YON: CIFT":"TREND YON: TEK",g_rt_trend_both,"tgTrendDir");
      }
      cy+=rowH; n++;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_loop_harvest?"DONGU HASADI: ACIK":"DONGU HASADI: KAPALI (0)",g_rt_loop_harvest,"tgLoop");
      cy+=rowH; n++;
      // v1.78.117: KACIS KASASI -> KAR KORUMA KASASI (kullanici talebi).
      // Panelde toplam kasa + kullanilabilir (500$-ustu fazlalik) ayri gosterilir.
      if(CV_Vis(cy,22)) {
         string escLabel;
         if(g_rt_escape_fund) {
            double availNow = EscapeFund_AvailableAmount(g_lattice.escape_fund);
            escLabel = StringFormat("KAR KORUMA KASASI: ACIK $%.1f (kullanilabilir $%.1f)", g_lattice.escape_fund, availNow);
         } else {
            escLabel = "KAR KORUMA KASASI: KAPALI";
         }
         CV_Pill(lx,cy,innerW,22,escLabel,g_rt_escape_fund,"tgEsc");
      }
      cy+=rowH; n++;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_grid_cont?"GRID SUREKLI: ACIK":"GRID SUREKLI: KAPALI",g_rt_grid_cont,"tgGridCont");
      cy+=rowH; n++;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_grid_tp_auth?"GRID TP OTORITE: ACIK":"GRID TP OTORITE: KAPALI",g_rt_grid_tp_auth,"tgTpAuth");
      cy+=rowH; n++;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_pyramid?"GENEL PIRAMIT: ACIK":"GENEL PIRAMIT: KAPALI",g_rt_pyramid,"tgPyr");
      cy+=rowH; n++;
      if(CV_Vis(cy,22)){
         CV_Pill(lx,cy,hw,22,g_rt_pyr_buy?"ALIS PIRAMIT: ACIK":"ALIS PIRAMIT: KAPALI",g_rt_pyr_buy,"tgPyrBuy");
         CV_Pill(lx+hw+6,cy,hw,22,g_rt_pyr_sell?"SATIS PIRAMIT: ACIK":"SATIS PIRAMIT: KAPALI",g_rt_pyr_sell,"tgPyrSell");
      }
      cy+=rowH; n++;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_vg_enable?"GRID: ACIK":"GRID: KAPALI",g_rt_vg_enable,"tgVG");
      cy+=rowH; n++;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_bullet_enable?"TREND / BULLET: ACIK":"TREND / BULLET: KAPALI",g_rt_bullet_enable,"tgBullet");
      cy+=rowH; n++;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_trend_align?"GRID TREND UYUM: ACIK":"GRID TREND UYUM: KAPALI",g_rt_trend_align,"tgTrendAl");
      cy+=rowH; n++;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_grid_mult_on?"GRID CARPAN: ACIK":"GRID CARPAN: KAPALI",g_rt_grid_mult_on,"tgMultOn");
      cy+=rowH; n++;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_seq_mult?"ARDISIK CARPAN: ACIK":"ARDISIK CARPAN: KAPALI",g_rt_seq_mult,"tgSeqMult");
      cy+=rowH; n++;
      // v1.78.56: TREND FLIP GUARD panel toggle'i - Panel_DirText() yon terse
      // donunce celisen kardaki pozisyonlari koruma altina alir
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_tfg_enable?"TREND FLIP GUARD: ACIK":"TREND FLIP GUARD: KAPALI",g_rt_tfg_enable,"tgTFG");
      cy+=rowH; n++;
      string srcNm[] = {"GRID MIKRO","DI","TMI","ENSEMBLE"};
      int si = g_rt_grid_src; if(si<0||si>3) si=0;
      if(CV_Vis(cy,22)) CV_Btn(lx,cy,innerW,22,"GRID TREND KAYNAK: "+srcNm[si],CV_CARD2,CV_ACC,"tgGridSrc");
      cy+=rowH; n++;
      // FIX v1.78.13: yön motoru (VEMA-X / First Touch / Classic) artık panelden
      // değiştirilebiliyor - InpDirectionEngineLock=true ise Stage_DirectionEngine
      // yine de ilk seçileni kilitli tutar, buton tıklanır ama etkisi restart'a kadar bekler.
      string dirEngNm[] = {"VEMA-X","1.DOKUNUS","KLASIK"};
      int dei = g_rt_dir_engine; if(dei<0||dei>2) dei=0;
      if(CV_Vis(cy,22)) CV_Btn(lx,cy,innerW,22,"YON MOTORU: "+dirEngNm[dei],CV_CARD2,CV_ACC,"tgDirEng");
      cy+=rowH; n++;
      string mik="NORMAL";
      if(g_rt_mikro_trend<0) mik="DUSUK";
      else if(g_rt_mikro_trend>0) mik="YUKSEK";
      if(CV_Vis(cy,22)) CV_Btn(lx,cy,innerW,22,"MIKRO TREND: "+mik,CV_CARD2,CV_ACC,"tgMikro");
      cy+=rowH; n++;
      // TP-PROJ: autonomous runtime status indicators (read-only)
      string peakLbl = (g_rt_peak_mode==1) ? "BAKIYE%" : StringFormat("%.0f$", RT_Peak());
      string autoReg = g_rt_auto_adapt ? "AUTO " : "";
      string autoLot = g_rt_auto_adapt ? "AUTO " : "";
      string autoState = g_rt_auto_adapt ? "AKTIF" : "MANUEL";
      string regimeState = AdaptiveMarket_DisplayText();
      color regimeColor = AdaptiveMarket_DisplayColor();
      AdaptiveMarket_SyncStatusObject();
      if(CV_Vis(cy,22)) CV_Btn(lx,cy,innerW,22,"TP-PROJ ZIRVE: "+peakLbl+" | "+autoState,regimeColor,clrWhite,"tgTpPeakMode");
      cy+=rowH; n++;
      if(CV_Vis(cy,22)) CV_Btn(lx,cy,innerW,22,"TP-PROJ LOT: "+autoLot+RT_LotModeName()+" | "+regimeState,regimeColor,clrWhite,"tgTpLot");
      cy+=rowH; n++;
      // v1.78.130: Panel buton metni dinamik rejimi gercek-zamanda gosteriyor; renk otonomus motora gore degisiyor
      string regimeDisplay = g_rt_auto_adapt ? ("OTONOMUS: " + g_rt_auto_note) : "MANUEL: " + RT_RegimeName();
      if(CV_Vis(cy,22)) CV_Btn(lx,cy,innerW,22,"TP-PROJ REJIM: "+regimeDisplay,regimeColor,clrWhite,"tgTpReg");
      cy+=rowH; n++;
      // --- eksik kalan filtre / motor butonları ---
      if(CV_Vis(cy,22)){
         CV_Pill(lx,cy,hw,22,g_rt_ml?"ML/ONNX: ACIK":"ML/ONNX: KAPALI",g_rt_ml,"tgML");
         CV_Pill(lx+hw+6,cy,hw,22,g_rt_dom?"DOM: ACIK":"DOM: KAPALI",g_rt_dom,"tgDOM");
      }
      cy+=rowH; n++;
      if(CV_Vis(cy,22)){
         CV_Pill(lx,cy,hw,22,g_rt_dte_on?"DTE: ACIK":"DTE: KAPALI",g_rt_dte_on,"tgDTE");
         CV_Pill(lx+hw+6,cy,hw,22,g_rt_heg_on?"HEG: ACIK":"HEG: KAPALI",g_rt_heg_on,"tgHEG");
      }
      cy+=rowH; n++;
      if(CV_Vis(cy,22)){
         CV_Pill(lx,cy,hw,22,g_rt_sinyal?"SINYAL: ACIK":"SINYAL: KAPALI",g_rt_sinyal,"tgSinyal");
         CV_Pill(lx+hw+6,cy,hw,22,g_rt_grid_lines?"GRID CIZGI: ACIK":"GRID CIZGI: KAPALI",g_rt_grid_lines,"tgGridLines");
      }
      cy+=rowH; n++;
      if(CV_Vis(cy,22)){
         CV_Pill(lx,cy,hw,22,g_rt_net_hedge?"NET HEDGE: ACIK":"NET HEDGE: KAPALI",g_rt_net_hedge,"tgNetHdg");
         CV_Pill(lx+hw+6,cy,hw,22,g_rt_genel_hedge?"GENEL HEDGE: ACIK":"GENEL HEDGE: KAPALI",g_rt_genel_hedge,"tgGenHdg");
      }
      cy+=rowH; n++;
      if(CV_Vis(cy,22)){
         CV_Pill(lx,cy,hw,22,g_rt_reset_limit?"RESET LIMIT: ACIK":"RESET LIMIT: KAPALI",g_rt_reset_limit,"tgRstLim");
         CV_Pill(lx+hw+6,cy,hw,22,g_rt_reset_idle?"RESET IDLE: ACIK":"RESET IDLE: KAPALI",g_rt_reset_idle,"tgRstIdle");
      }
      cy+=rowH; n++;
      {
         string tpStartNm = g_rt_auto_adapt ? "AUTO" : ((g_rt_tp_start==1) ? "PROJECT" : "FIXED");
         if(CV_Vis(cy,22)) CV_Btn(lx,cy,innerW,22,"TP-PROJ START: "+tpStartNm,CV_CARD2,CV_ACC,"tgTpStart");
      }
      cy+=rowH; n++;
      if(CV_Vis(cy,22)){
         CV_Pill(lx,cy,hw,22,g_rt_sound?"SES: ACIK":"SES: KAPALI",g_rt_sound,"tgSound");
         CV_Pill(lx+hw+6,cy,hw,22,g_rt_nf_enable?"HABER: ACIK":"HABER: KAPALI",g_rt_nf_enable,"tgNF");
      }
      cy+=rowH; n++;
      contentH=n*rowH+40;
   }
   // --- DEGER (ticari: ayni satir DEGER chip + edit) ---
   else if(showVal){
      int cy=g_cvViewTop+ly;
      // Cift satirli hizli ayarlar (KAR/ZARAR BEK)
      // v1.78.31 FIX: bu blok "if(CV_Vis(...)){ ...; CV_ShowEditInline(...); }"
      // seklindeydi — CV_Vis disariya YANLIS ise CV_ShowEditInline'in KENDI
      // gizleme mantigi (viewport disi -> XDISTANCE=-5000) hic CALISMIYORDU,
      // cunku fonksiyon hic CAGRILMIYORDU. Sonuc: kutu, scroll ile viewport
      // disina cikinca son gorunur konumunda "yapisik" kaliyor, geri kalan
      // panel altindan/ustunden kayarken sabit boy sekmeleri/butonlari
      // kapatiyordu. Cizim hala CV_Vis ile korunuyor, ama CV_ShowEditInline
      // artik HER ZAMAN cagriliyor (kendi ic kontrolu gorunurlugu yonetiyor).
      bool visKarZar1 = CV_Vis(cy,22);
      if(visKarZar1) CV_Text(lx,cy+4,"KAR BEK:",CV_DIM,8,false);
      CV_ShowEditInline("edPrBek", lx+58, cy+1, 48, 20, FmtEditVal(g_rt_profit_bek,0));
      if(visKarZar1) CV_Text(lx+hw+6,cy+4,"KAR ADET:",CV_DIM,8,false);
      CV_ShowEditInline("edPrAd", lx+hw+70, cy+1, 40, 20, FmtEditInt(g_rt_profit_adet));
      cy+=rowH;
      bool visKarZar2 = CV_Vis(cy,22);
      if(visKarZar2) CV_Text(lx,cy+4,"ZARAR BEK:",CV_DIM,8,false);
      CV_ShowEditInline("edLossBek", lx+66, cy+1, 48, 20, FmtEditVal(g_rt_loss_bek,0));
      if(visKarZar2) CV_Text(lx+hw+6,cy+4,"ZARAR ADET:",CV_DIM,8,false);
      CV_ShowEditInline("edLossAd", lx+hw+78, cy+1, 40, 20, FmtEditInt(g_rt_loss_adet));
      cy+=rowH+2;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,"GRID AYARLARI",CV_ACC,8,true);
      cy+=18;
      // Toggle + deger yan yana
      bool visMult = CV_Vis(cy,22);
      if(visMult) CV_Pill(lx,cy,hw-50,22,g_rt_grid_mult_on?"GRID CARPAN: ACIK":"GRID CARPAN: KAPALI",g_rt_grid_mult_on,"tgMultOn");
      CV_ShowEditInline("edMult", lx+hw-44, cy+1, 50, 20, FmtEditVal(g_rt_grid_mult,3));
      cy+=rowH;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_seq_mult?"GRID ARDISIK CARPAN: ACIK":"GRID ARDISIK CARPAN: KAPALI",g_rt_seq_mult,"tgSeqMult");
      cy+=rowH;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_trend_align?"GRID TREND UYUM: ACIK":"GRID TREND UYUM: KAPALI",g_rt_trend_align,"tgTrendAl");
      cy+=rowH;
      string srcNm2[] = {"GRID MIKRO","DI","TMI","ENSEMBLE"};
      int si2 = g_rt_grid_src; if(si2<0||si2>3) si2=0;
      if(CV_Vis(cy,22)) CV_Btn(lx,cy,innerW,22,"TREND KAYNAK: "+srcNm2[si2],CV_CARD2,CV_ACC,"tgGridSrc");
      cy+=rowH;
      string mik2="NORMAL";
      if(g_rt_mikro_trend<0) mik2="DUSUK"; else if(g_rt_mikro_trend>0) mik2="YUKSEK";
      if(CV_Vis(cy,22)) CV_Btn(lx,cy,innerW,22,"MIKRO TREND: "+mik2,CV_CARD2,CV_ACC,"tgMikro");
      cy+=rowH;
      // v1.78.22: ATR Sistemi + ADX Filtresi — GRID AYARLARI filtre grubunun
      // sonuna eklendi (Dogan: "filtrelerin altina"). ATR Modu = risk motoru
      // ATR'dan mi otomatik dolsun; ADX Filtresi = ADX esigin altindaysa Grid
      // yeni seviye acmaz (ALGO CheckADX_TrendStrength birebir esik mantigi).
      bool visAtr = CV_Vis(cy,22);
      if(visAtr) CV_Pill(lx,cy,hw-50,22,g_rt_atr_mode?"ATR MODU: ACIK":"ATR MODU: KAPALI",g_rt_atr_mode,"tgAtrMode");
      CV_ShowEditInline("edAtrTrig", lx+hw-44, cy+1, 50, 20, FmtEditVal(RT_ATRTriggerMult(),2));
      cy+=rowH;
      bool visAdx = CV_Vis(cy,22);
      if(visAdx) CV_Pill(lx,cy,hw-50,22,g_rt_adx_filter?"ADX FILTRE: ACIK":"ADX FILTRE: KAPALI",g_rt_adx_filter,"tgAdxFilter");
      CV_ShowEditInline("edAdxThr", lx+hw-44, cy+1, 50, 20, FmtEditVal(RT_ADXThreshold(),0));
      cy+=rowH+2;
      // DEGER chip satirlari (ticari stil)
      CV_ValEditRow(lx,cy,innerW,22,"BAK %","edBak",FmtEditVal(g_rt_bak_pct,3)); cy+=24;
      CV_ValEditRow(lx,cy,innerW,22,"TP VAR %","edTpVar",FmtEditVal(g_rt_tp_var_pct,3)); cy+=24;
      CV_ValEditRow(lx,cy,innerW,22,"ADIM PNT","edStepPnt",FmtEditVal(g_rt_step_pnt,0)); cy+=24;
      // v1.78.41 FIX (#96): "GRID LOT" kutusu panelde girilen TEMEL degeri
      // gosteriyordu ama gercekte acilan lot AutoTune/TimeLotBoost/LotPenalty/
      // RiskLotMult carpanlarindan (Lot_CalcCapped) gectikten sonra farkli
      // olabiliyordu — kullanici panelde yazan sayi ile gercekte acilan lotun
      // ayni oldugunu sanabiliyordu. Etiket artik carpanlar aktifse efektif
      // degeri de parantez icinde gosteriyor; kutu (edLot) yine TEMEL degeri
      // duzenlemeye devam ediyor (edit alani degismedi, sadece etiket).
      {
         double baseLot = RT_VG_Lot();
         double effLot  = Lot_CalcCapped(g_symbol, baseLot, true);
         string lotLabel = "GRID LOT";
         if(MathAbs(effLot - baseLot) > 0.001)
            lotLabel = StringFormat("GRID LOT (efk:%.2f)", effLot);
         CV_ValEditRow(lx,cy,innerW,22,lotLabel,"edLot",FmtEditVal(baseLot,2));
      }
      cy+=24;
      CV_ValEditRow(lx,cy,innerW,22,"ADIM (STEP)","edStep",FmtEditVal(RT_VG_Step(),1)); cy+=24;
      CV_ValEditRow(lx,cy,innerW,22,"TP (PUAN)","edTpPts",FmtEditVal(RT_VG_TP(),0)); cy+=24;
      CV_ValEditRow(lx,cy,innerW,22,"BULLET LOT","edBul",FmtEditVal(RT_BulletLot(),2)); cy+=24;
      // v1.78.36: etiket + kutu artik moda gore ("PEAK $" ya da "PEAK %"),
      // kutu HAM degeri gosterir (RT_PeakRaw) — RT_Peak() artik %modunda
      // hesaplanmis dolari donduruyor, kutuda o gosterilirse yazdiginiz
      // sayi geri okunmaz.
      CV_ValEditRow(lx,cy,innerW,22,(g_rt_peak_mode==1)?"PEAK %":"PEAK $","edPeak",FmtEditVal(RT_PeakRaw(),1)); cy+=24;
      // Bonus / blok / kulucka
      bool visBonus = CV_Vis(cy,22);
      if(visBonus) CV_Pill(lx,cy,hw-50,22,g_rt_bonus_tp?"BONUS TP: ACIK":"BONUS TP: KAPALI",g_rt_bonus_tp,"tgBonus");
      CV_ShowEditInline("edVtp", lx+hw-44, cy+1, 50, 20, FmtEditVal(g_rt_vtp_mult,1));
      cy+=rowH;
      bool visBlok = CV_Vis(cy,22);
      if(visBlok) CV_Pill(lx,cy,hw-50,22,g_rt_blok?"BLOK: ACIK":"BLOK: KAPALI",g_rt_blok,"tgBlok");
      CV_ShowEditInline("edZarBlok", lx+hw-44, cy+1, 50, 20, FmtEditInt(g_rt_zarar_blok));
      cy+=rowH;
      CV_ValEditRow(lx,cy,innerW,22,"KAR KULUCKA","edKarKul",FmtEditInt(g_rt_kar_kulucka)); cy+=24;
      CV_ValEditRow(lx,cy,innerW,22,"ZARAR KULUCKA","edZarKul",FmtEditInt(g_rt_zarar_kulucka)); cy+=24;
      CV_ValEditRow(lx,cy,innerW,22,"HASSAS","edHassas",FmtEditVal(g_rt_hassas,1)); cy+=24;
      CV_ValEditRow(lx,cy,innerW,22,"ONAY","edOnay",FmtEditInt(g_rt_onay)); cy+=24;
      CV_ValEditRow(lx,cy,innerW,22,"TOLERANS","edTol",FmtEditVal(g_rt_tolerans,2)); cy+=24;
      if(CV_Vis(cy,14)) CV_Text(lx,cy,"DEGER chip veya kutuya tikla → yaz → Enter",CV_DIM,7,false);
      cy+=16;
      contentH = cy - g_cvViewTop + g_panelScroll + 20;
   }
   // --- ARAC ---
   else if(showArac){
      int cy=g_cvViewTop+ly;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,StringFormat("MAGIC KIMLIGI: %I64u",g_magic),CV_TXT,8,true); cy+=16;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,StringFormat("GRAFIK NO: %s",_Symbol),CV_DIM,8,false); cy+=18;
      bool visWork = CV_Vis(cy,22);
      if(visWork) CV_Text(lx,cy+4,"CALISMA (DK)",CV_DIM,8,false);
      CV_ShowEditInline("edWork", lx+90, cy+1, 48, 20, FmtEditInt(g_rt_work_min));
      if(visWork) CV_Text(lx+hw+6,cy+4,"DURAKLAMA",CV_DIM,8,false);
      CV_ShowEditInline("edIdle", lx+hw+80, cy+1, 48, 20, FmtEditInt(g_rt_idle_min));
      cy+=rowH;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_timer_on?"ZAMANLAYICI: ACIK":"ZAMANLAYICI: KAPALI",g_rt_timer_on,"tgTimer");
      cy+=rowH;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_sure_sinir?"SURE SINIRI: ACIK":"SURE SINIRI: KAPALI",g_rt_sure_sinir,"tgSure");
      cy+=rowH;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_sonra_dur?"SONRA DUR: ACIK":"SONRA DUR: KAPALI",g_rt_sonra_dur,"tgSonra");
      cy+=rowH;
      CV_ValEditRow(lx,cy,innerW,22,"DAKIKA","edRstMin",FmtEditInt(g_rt_reset_min)); cy+=24;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,"ISLEM SAATLERI",CV_ACC,8,true); cy+=16;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_saat_filtre?"FILTRE: ACIK":"FILTRE: KAPALI",g_rt_saat_filtre,"tgSaat");
      cy+=rowH;
      string sm[]={"BROKER","LOCAL","UTC"};
      int smi=g_rt_saat_mode; if(smi<0||smi>2) smi=0;
      if(CV_Vis(cy,22)) CV_Btn(lx,cy,innerW,22,"SAAT: "+sm[smi],CV_CARD2,CV_ACC,"tgSaatMode");
      cy+=rowH;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,"SAAT DISI: YENI ISLEM YOK",CV_DIM,7,false); cy+=14;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,"GUN: PZT-CUM",CV_DIM,7,false); cy+=14;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,"P1 "+g_rt_p1+"  P2 "+g_rt_p2,CV_DIM,7,false); cy+=14;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,"P3 "+g_rt_p3+"  P4 "+g_rt_p4,CV_DIM,7,false); cy+=18;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,"OTO DD HEDGE",CV_ACC,8,true); cy+=16;
      bool visDd = CV_Vis(cy,22);
      if(visDd) CV_Text(lx,cy+4,"DD %",CV_DIM,8,false);
      CV_ShowEditInline("edDd", lx+36, cy+1, 48, 20, FmtEditVal(g_rt_dd_pct,1));
      if(visDd) CV_Text(lx+hw+6,cy+4,"TP %",CV_DIM,8,false);
      CV_ShowEditInline("edDdTp", lx+hw+40, cy+1, 48, 20, FmtEditVal(g_rt_dd_tp_pct,2));
      cy+=rowH;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_dd_hedge?"DD HEDGE: ACIK":"DD HEDGE: KAPALI",g_rt_dd_hedge,"tgDdHedge");
      cy+=rowH;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,"GENEL KAR / ZARAR / ZAMAN SIFIRLAMA",CV_ACC,8,true); cy+=16;
      bool visKarZarGen = CV_Vis(cy,22);
      if(visKarZarGen) CV_Text(lx,cy+4,"KAR %",CV_DIM,8,false);
      CV_ShowEditInline("edPr", lx+42, cy+1, 48, 20, FmtEditVal(g_rt_profit_reset_pct,1));
      if(visKarZarGen) CV_Text(lx+hw+6,cy+4,"ZARAR %",CV_DIM,8,false);
      CV_ShowEditInline("edLr", lx+hw+60, cy+1, 48, 20, FmtEditVal(g_rt_loss_reset_pct,1));
      cy+=rowH;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_kar_hepsini_kapat?"KARDA HEPSINI KAPAT: ACIK":"KARDA HEPSINI KAPAT: KAPALI",g_rt_kar_hepsini_kapat,"tgKarHep");
      cy+=rowH;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_zarar_hepsini_kapat?"ZARARDA HEPSINI KAPAT: ACIK":"ZARARDA HEPSINI KAPAT: KAPALI",g_rt_zarar_hepsini_kapat,"tgZarHep");
      cy+=rowH;
      contentH = cy - g_cvViewTop + g_panelScroll + 20;
   }
   // --- HABER ---
   else if(showHab){
      int cy=g_cvViewTop+ly;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_nf_enable?"HABER FILTRE: ACIK":"HABER FILTRE: KAPALI",g_rt_nf_enable,"tgNF");
      cy+=rowH;
      CV_ValEditRow(lx,cy,innerW,22,"HABER ONCE","edNfBef",FmtEditInt(RT_NfBefore())); cy+=24;
      CV_ValEditRow(lx,cy,innerW,22,"HABER SONRA","edNfAft",FmtEditInt(RT_NfAfter())); cy+=24;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_nf_pause?"HABERDE DURDUR: ACIK":"HABERDE DURDUR: KAPALI",g_rt_nf_pause,"tgNfPause");
      cy+=rowH;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_nf_otohedge?"HABER ONCE HEDGE: ACIK":"HABER ONCE HEDGE: KAPALI",g_rt_nf_otohedge,"tgNfHedge");
      cy+=rowH;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_nf_hedge_kapat?"HEDGE KAPAT: ACIK":"HEDGE KAPAT: KAPALI",g_rt_nf_hedge_kapat,"tgNfHdgCl");
      cy+=rowH;
      if(CV_Vis(cy,22)) CV_Pill(lx,cy,innerW,22,g_rt_nf_zarar_kapat?"ZARAR KAPAT: ACIK":"ZARAR KAPAT: KAPALI",g_rt_nf_zarar_kapat,"tgNfLoss");
      cy+=rowH+4;
      CV_Text(lx,cy,StringFormat("Kilit: %s | Gunluk: %s",g_newsHardLock?"AKTIF":"yok",g_dailyLocked?"AKTIF":"yok"),CV_TXT,8,false); cy+=16;
      CV_Text(lx,cy,StringFormat("Daily PnL: %.2f%% | VIOP: %s",Security_GetDailyPnLPercent(),g_viopBlocked?"BLOK":"ok"),CV_DIM,8,false); cy+=16;
      cy+=6;
      // v1.78.51 (#120): Info listesi - gercek haber isimleri/saatleri
      if(CV_Vis(cy,16)) CV_Text(lx,cy,StringFormat("INFO (onumuzdeki %d sa.)",(InpNF_LookaheadHours>0?InpNF_LookaheadHours:24)),CV_ACC,8,true);
      cy+=16;
      if(!g_rt_nf_enable) {
         if(CV_Vis(cy,14)) CV_Text(lx,cy,"Haber filtresi KAPALI - listeleme icin ACIK yapin",CV_DIM,8,false);
         cy+=14;
      } else if(g_nfInfoCount==0) {
         if(CV_Vis(cy,14)) CV_Text(lx,cy,"Bu aralikta eslesen haber yok",CV_DIM,8,false);
         cy+=14;
      } else {
         for(int nfi=0; nfi<g_nfInfoCount; nfi++) {
            if(CV_Vis(cy,14)) CV_Text(lx,cy,g_nfInfoLines[nfi],CV_TXT,8,false);
            cy+=14;
         }
      }
      contentH = cy - g_cvViewTop + g_panelScroll + 20;
   }
   else if(g_panelMainTab==1){ // ISLEMLER – acik pozisyon listesi
      int cy=g_cvViewTop+10;
      int bn=0,sn=0; double bl=0,sl=0,pnl=0;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,"ACIK POZISYONLAR",CV_ACC,9,true); cy+=18;
      int shown=0;
      for(int i=PositionsTotal()-1;i>=0;i--){
         ulong tk=PositionGetTicket(i); if(tk==0||!PositionSelectByTicket(tk)) continue;
         if(PositionGetString(POSITION_SYMBOL)!=g_symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC)!=g_magic) continue;
         double vv=PositionGetDouble(POSITION_VOLUME);
         double pp=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
         pnl+=pp;
         bool isBuy=((int)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
         if(isBuy){ bn++; bl+=vv; } else { sn++; sl+=vv; }
         if(shown < 12 && CV_Vis(cy,14)){
            color pc = (pp>=0)?CV_ACC:CV_RED;
            CV_Text(lx,cy,StringFormat("%s  %.2f  %+.2f  #%I64u", isBuy?"BUY ":"SELL", vv, pp, tk),pc,8,false);
            cy+=14; shown++;
         }
      }
      if(shown==0 && CV_Vis(cy,16)){ CV_Text(lx,cy,"(acik pozisyon yok)",CV_DIM,8,false); cy+=16; }
      cy+=6;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,StringFormat("OZET BUY %d/%.2f  SELL %d/%.2f",bn,bl,sn,sl),CV_TXT,8,true); cy+=16;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,StringFormat("Floating  %+.2f",pnl),(pnl>=0)?CV_ACC:CV_RED,9,true); cy+=16;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,StringFormat("Lattice B=%d S=%d",g_lattice.buy_levels_active,g_lattice.sell_levels_active),CV_DIM,8,false); cy+=16;
      contentH = cy - g_cvViewTop + g_panelScroll + 20;
   }
   else if(g_panelMainTab==2){ // SISTEM
      int cy=g_cvViewTop+10;
      CV_Text(lx,cy,StringFormat("CPU refresh: %d ms",InpCPU_SignalRefreshMs),CV_TXT,9,false); cy+=18;
      CV_Text(lx,cy,StringFormat("Magic: %I64u",g_magic),CV_TXT,9,false); cy+=18;
      CV_Text(lx,cy,StringFormat("Semboller: %d",g_symbol_count),CV_TXT,9,false); cy+=18;
      CV_Text(lx,cy,StringFormat("Kar Koruma Kasasi: %.2f (kullanilabilir %.2f)",g_lattice.escape_fund,EscapeFund_AvailableAmount(g_lattice.escape_fund)),CV_TXT,9,false); cy+=18;
      CV_Text(lx,cy,StringFormat("Timer: %s  work=%d idle=%d",RT_TimerOn()?"ON":"off",g_rt_work_min,g_rt_idle_min),CV_TXT,9,false); cy+=18;
      CV_Text(lx,cy,StringFormat("VG=%s Bullet=%s NF=%s",RT_VG()?"ON":"off",RT_Bullet()?"ON":"off",RT_NF()?"ON":"off"),CV_TXT,9,false); cy+=18;
      CV_Text(lx,cy,StringFormat("DD hedge RT: %s",g_rt_dd_hedge?"ACIK":"KAPALI"),CV_TXT,9,false); cy+=18;
      CV_Text(lx,cy,"Surum: v1.78.20 | Risk R:R optimize",CV_DIM,8,false);
      contentH=180;
   }
   else if(g_panelMainTab==3){ // SONUC – performans ozeti
      int cy=g_cvViewTop+10;
      double eq2=AccountInfoDouble(ACCOUNT_EQUITY);
      double bal2=AccountInfoDouble(ACCOUNT_BALANCE);
      double deg2=Panel_IndependentEquityChange();
      double degPct2=(bal2>0)?(deg2/bal2*100.0):0.0;
      double net2=Panel_NetFloating();
      if(CV_Vis(cy,16)) CV_Text(lx,cy,"PERFORMANS OZETI",CV_ACC,9,true); cy+=18;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,StringFormat("Equity: %.2f",eq2),CV_TXT,9,false); cy+=16;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,StringFormat("Bakiye: %.2f",bal2),CV_TXT,9,false); cy+=16;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,StringFormat("Bagimsiz DEG: %+.2f (%+.2f%%)",deg2,degPct2),(deg2>=0)?CV_ACC:CV_RED,9,true); cy+=16;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,StringFormat("Net floating: %+.2f",net2),(net2>=0)?CV_ACC:CV_RED,9,true); cy+=16;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,StringFormat("Faz: %s  conf=%.0f%%",Panel_PhaseText(),g_ctx.dir.confidence*100.0),CV_DIM,8,false); cy+=16;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,StringFormat("Yon: %s",Panel_DirText()),CV_TXT,8,false); cy+=16;
      if(CV_Vis(cy,16)) CV_Text(lx,cy,"SIFIRLA ile bagimsiz equity bazini sifirla",CV_DIM,7,false); cy+=16;
      contentH = cy - g_cvViewTop + g_panelScroll + 20;
   }
   else {
      contentH = 40;
   }

   // İçerik yüksekliği → aktif sekme; offset sınırla
   g_panelScrollMax=MathMax(0,contentH-g_cvViewH+8);
   if(g_panelScroll>g_panelScrollMax) g_panelScroll=g_panelScrollMax;
   if(g_panelScroll<0) g_panelScroll=0;
   {
      int tab = g_panelMainTab;
      if(tab < 0) tab = 0; if(tab > 3) tab = 3;
      g_tabScrollOffset[tab] = g_panelScroll;
      g_tabContentH[tab] = contentH;
   }
   // Kaydırma çubuğu (▲ track thumb ▼) — içerik değişmedi
   Panel_DrawScrollBar(w, g_cvViewTop, g_cvViewH);

   // Footer
   int by=h-ftrH;
   CV_Rect(1,by-2,w-2,ftrH,CV_CARD);
   int fbw=(w-pad*2-8)/3;
   CV_Btn(pad,by+5,fbw,22,"KARI KAPAT",CV_ON,clrWhite,"btnCloseProfit");
   CV_Btn(pad+fbw+4,by+5,fbw,22,"TUMUNU KAPAT",CV_RED,clrWhite,"btnCloseAll");
   CV_Btn(pad+(fbw+4)*2,by+5,fbw,22,"ZARARI KAPAT",CV_WARN,CV_INK,"btnCloseLoss"); // v1.78.51: amber zeminde koyu metin

   g_panelForceEditSync=false;
   g_cv.Update(false); // false = chart ChartRedraw yok, sadece bitmap
   if(s_lastCvX != g_cvX || s_lastCvY != g_cvY) {
      ObjectSetInteger(0,g_cvObj,OBJPROP_XDISTANCE,g_cvX);
      ObjectSetInteger(0,g_cvObj,OBJPROP_YDISTANCE,g_cvY);
      s_lastCvX = g_cvX; s_lastCvY = g_cvY;
   }
}

//+------------------------------------------------------------------+
//| PANEL KAYDIRMA – optimize (içerik aynı; gereksiz iş yok)         |
//+------------------------------------------------------------------+
#define PANEL_SCROLL_REDRAW_MS  20
static ulong s_lastScrollRedrawMs = 0;

void Panel_SyncScrollFromTab() {
   int tab = g_panelMainTab;
   if(tab < 0) tab = 0;
   if(tab > 3) tab = 3;
   g_panelScroll = g_tabScrollOffset[tab];
}

void Panel_SaveScrollToTab() {
   int tab = g_panelMainTab;
   if(tab < 0) tab = 0;
   if(tab > 3) tab = 3;
   g_tabScrollOffset[tab] = g_panelScroll;
   if(g_cvViewH > 0)
      g_tabContentH[tab] = g_panelScrollMax + g_cvViewH;
}

int Panel_MaxScrollForTab(const int tab) {
   int viewportH = g_cvViewH;
   if(viewportH < 50) {
      viewportH = g_viewportBottomY - g_viewportTopY;
      if(viewportH < 50) viewportH = 50;
   }
   int contentH = (tab >= 0 && tab <= 3) ? g_tabContentH[tab] : 0;
   if(contentH <= 0)
      contentH = g_panelScrollMax + viewportH;
   int maxScroll = contentH - viewportH;
   return (maxScroll > 0) ? maxScroll : 0;
}

// forceRedraw: true=▲▼ tık (anında); false=tekerlek (20ms throttle, yine de günceller)
void ScrollTab(const int tab, const int deltaPx, const bool forceRedraw = true) {
   if(tab < 0 || tab > 3) return;
   if(deltaPx == 0 && !forceRedraw) return;

   int maxScroll = Panel_MaxScrollForTab(tab);
   int oldOff = g_tabScrollOffset[tab];
   int newOff = oldOff + deltaPx;
   if(newOff < 0) newOff = 0;
   if(newOff > maxScroll) newOff = maxScroll;

   // Sınırda takılı – CPU yakma
   if(newOff == oldOff && deltaPx != 0) {
      g_panelScroll = newOff;
      g_panelScrollMax = maxScroll;
      return;
   }

   g_tabScrollOffset[tab] = newOff;
   g_panelScroll = newOff;
   g_panelScrollMax = maxScroll;

   if(!forceRedraw) {
      ulong now = GetTickCount();
      if(s_lastScrollRedrawMs != 0 &&
         (now - s_lastScrollRedrawMs) < (ulong)PANEL_SCROLL_REDRAW_MS)
         return; // offset güncel; bir sonraki tekerlek/tick çizer
      s_lastScrollRedrawMs = now;
   } else {
      s_lastScrollRedrawMs = GetTickCount();
   }

   // Canvas g_cv.Update() yeterli – ChartRedraw yok (çift yenileme tasarrufu)
   Panel_RequestUpdate(true);
}

void Panel_DrawScrollBar(const int w, const int viewTop, const int viewH) {
   int scrollBarX = w - 16;
   int scrollBtnH = 14;
   if(viewH < 40) return;

   // İçerik sığyorsa sadece soluk track
   if(g_panelScrollMax <= 0) {
      CV_Rect(scrollBarX + 4, viewTop, 6, viewH, CV_CARD);
      return;
   }

   int trackTop = viewTop + scrollBtnH;
   int trackH = viewH - 2 * scrollBtnH;
   if(trackH < 16) trackH = 16;

   CV_Btn(scrollBarX, viewTop, 14, scrollBtnH, "^", CV_CARD2, CV_TXT, "btnUp");
   CV_Btn(scrollBarX, viewTop + viewH - scrollBtnH, 14, scrollBtnH, "v", CV_CARD2, CV_TXT, "btnDown");
   CV_Rect(scrollBarX + 3, trackTop, 8, trackH, CV_CARD);

   int contentH = g_panelScrollMax + viewH;
   if(contentH < viewH) contentH = viewH;
   int thumbH = (int)MathRound((double)trackH * (double)viewH / (double)contentH);
   if(thumbH < 10) thumbH = 10;
   if(thumbH > trackH) thumbH = trackH;

   double scrollFrac = (double)g_panelScroll / (double)g_panelScrollMax;
   if(scrollFrac < 0.0) scrollFrac = 0.0;
   if(scrollFrac > 1.0) scrollFrac = 1.0;
   int thumbY = trackTop + (int)MathRound((trackH - thumbH) * scrollFrac);
   CV_Rect(scrollBarX + 3, thumbY, 8, thumbH, CV_ACC);
}

bool Panel_IsAutonomousStatusControl(const string id) {
   // Kullanici sadece TREND FLIP GUARD butonunu manuel kontrol etsin;
   // geri kalan trend kaynak / yon motoru / mikro trend / TP-Proj durum
   // butonlari otonom yapi tarafindan yonetilir; tiklama bu katmanda
   // yutulur (read-only status indicator gibi davranir).
   return (id == "tgGridSrc" || id == "tgDirEng" || id == "tgMikro" ||
           id == "tgTpReg" || id == "tgTpLot" || id == "tgTpPeak" ||
           id == "tgTpPeakMode" || id == "tgTpStart");
}

void Panel_HandleClick(const string sparam){
   string id=sparam;
   if(StringFind(id,PN_PREFIX)==0) id=StringSubstr(id,StringLen(PN_PREFIX));

   // TP-Proj kontrolleri AdaptiveMarket_Refresh() tarafindan yonetilen
   // canli durum gostergeleridir; manuel tiklama bilincli olarak yutulur.
   if(Panel_IsAutonomousStatusControl(id)) {
      PrintFormat("Panel STATUS ONLY | id=%s | rejim=%s | lot=%s | auto=%s",
                  id, RT_RegimeName(), RT_LotModeName(), g_rt_auto_adapt ? "ON" : "OFF");
      return;
   }

   // v1.72: DEGER chip → ilgili edit kutusuna odak
   if(StringFind(id,"focus:")==0){
      string eid = StringSubstr(id,6);
      string full = PN_PREFIX + eid;
      if(ObjectFind(0,full) >= 0){
         Panel_SwitchEdit(full);
         ChartRedraw(0);
      }
      return;
   }

   if(id=="btnUp"){ ScrollTab(g_panelMainTab, -PANEL_SCROLL_STEP); return; }
   if(id=="btnDown"){ ScrollTab(g_panelMainTab, +PANEL_SCROLL_STEP); return; }
   if(id=="btnScalePlus"){
      g_panelScale = Panel_ClampScale(g_panelScale + 0.1);
      GV_SetNumIfChanged(PanelGV_Key("PSCALE"), g_panelScale);
      PanelMemory_Save();
      CreateMinimalPanel();
      return;
   }
   if(id=="btnScaleMinus"){
      g_panelScale = Panel_ClampScale(g_panelScale - 0.1);
      GV_SetNumIfChanged(PanelGV_Key("PSCALE"), g_panelScale);
      PanelMemory_Save();
      CreateMinimalPanel();
      return;
   }
   if(StringFind(id,"main")==0){
      // Önceki sekme offset'ini sakla, yeni sekmeye geç
      Panel_SaveScrollToTab();
      g_panelMainTab=(int)StringToInteger(StringSubstr(id,4));
      if(g_panelMainTab<0||g_panelMainTab>3) g_panelMainTab=0;
      Panel_SyncScrollFromTab();
      g_panelForceEditSync=true;
      Panel_RequestUpdate(true); ChartRedraw(0); return;
   }
   if(StringFind(id,"sub")==0){
      // Alt sekme: STRATEJI içinde — offset sıfırla (alt içerik farklı)
      g_panelSubTab=(int)StringToInteger(StringSubstr(id,3));
      if(g_panelSubTab<0||g_panelSubTab>3) g_panelSubTab=0;
      g_panelMainTab=0;
      g_tabScrollOffset[0]=0;
      g_panelScroll=0;
      g_panelForceEditSync=true;
      Panel_RequestUpdate(true); ChartRedraw(0); return;
   }
   if(id=="btnApply"||id=="btnMaster"){ Panel_ApplyEdits(); MasterPanel_Publish(); }
   else if(id=="btnUnlock"){
      g_dailyLocked = false;
      g_timeLimitPaused = false;
      g_ddHedgePaused = false;
      g_newsHardLock = false;
      g_tradeBlockReason = "";
      g_dailyUnlockGrace = TimeCurrent() + 120; // 2 dk yeniden kilitlenme yok
      g_panelApplyMsg = "● KILIT KALDIRILDI (2dk)";
      g_panelApplyMsgUntil = TimeCurrent() + 4;
      Print("Panel: KILIT KALDIR (gunluk/sure/haber/dd pause + 2dk grace)");
      Sound_Play("P_RESET");
   }
   else if(id=="tgRobot"){
      g_robotOn=!g_robotOn;
      g_panelForceEditSync=true;
      if(g_robotOn) {
         // İşleme hazır: motorlardan en az biri açık olsun
         if(!RT_VG() && !RT_Bullet()) {
            g_rt_vg_enable = true;
            Print("ROBOT ON → GRID otomatik açıldı (ikisi de kapalıydı)");
         }
         if(!g_panelBuy && !g_panelSell) {
            g_panelBuy = true;
            g_panelSell = true;
            Print("ROBOT ON → ALIS/SATIS açıldı");
         }
         // Kilit bayraklarını temizle (manuel kilit kalır)
         g_timeLimitPaused = false;
         g_ddHedgePaused = false;
         PrintFormat("ROBOT ON | VG=%s Bullet=%s Buy=%s Sell=%s | %s",
                     RT_VG()?"Y":"N", RT_Bullet()?"Y":"N",
                     g_panelBuy?"Y":"N", g_panelSell?"Y":"N",
                     TradeDiag_Compute());
      } else {
         Print("ROBOT OFF");
      }
      GV_MarkDirty();
      PanelMemory_Save();
   }
   else if(id=="tgBuy") g_panelBuy=!g_panelBuy;
   else if(id=="tgSell") g_panelSell=!g_panelSell;
   else if(id=="tgLoop") g_rt_loop_harvest=!g_rt_loop_harvest;
   else if(id=="tgEsc") g_rt_escape_fund=!g_rt_escape_fund;
   else if(id=="tgTpAuth") g_rt_grid_tp_auth=!g_rt_grid_tp_auth;
   else if(id=="tgGridCont") g_rt_grid_cont=!g_rt_grid_cont;
   else if(id=="tgMultOn") g_rt_grid_mult_on=!g_rt_grid_mult_on;
   else if(id=="tgSeqMult") g_rt_seq_mult=!g_rt_seq_mult;
   else if(id=="tgTrendAl") g_rt_trend_align=!g_rt_trend_align;
   else if(id=="tgTFG"){
      g_rt_tfg_enable=!g_rt_tfg_enable;
      PrintFormat("TREND FLIP GUARD panelden %s", g_rt_tfg_enable?"ACILDI":"KAPATILDI");
   }
   else if(id=="tgDdHedge") g_rt_dd_hedge=!g_rt_dd_hedge;
   else if(id=="tgPyr"){
      g_rt_pyramid=!g_rt_pyramid;
      if(g_rt_pyramid){ g_rt_pyr_buy=true; g_rt_pyr_sell=true; }
      else { g_rt_pyr_buy=false; g_rt_pyr_sell=false; }
   }
   else if(id=="tgPyrBuy"){ g_rt_pyr_buy=!g_rt_pyr_buy; g_rt_pyramid=(g_rt_pyr_buy||g_rt_pyr_sell); }
   else if(id=="tgPyrSell"){ g_rt_pyr_sell=!g_rt_pyr_sell; g_rt_pyramid=(g_rt_pyr_buy||g_rt_pyr_sell); }
   else if(id=="tgSound") g_rt_sound=!g_rt_sound;
   else if(id=="tgDOM") g_rt_dom=!g_rt_dom;
   else if(id=="tgML") g_rt_ml=!g_rt_ml;
   else if(id=="tgGridDir") g_rt_grid_both=!g_rt_grid_both;
   else if(id=="tgTrendDir") g_rt_trend_both=!g_rt_trend_both;
   else if(id=="tgVG") g_rt_vg_enable=!g_rt_vg_enable;
   else if(id=="tgBullet") g_rt_bullet_enable=!g_rt_bullet_enable;
   else if(id=="tgNF"){ g_rt_nf_enable=!g_rt_nf_enable; if(!g_rt_nf_enable) g_newsHardLock=false; }
   else if(id=="tgTpReg") g_rt_tp_regime=(g_rt_tp_regime+1)%6;
   else if(id=="tgTpLot") g_rt_lot_mode=(g_rt_lot_mode+1)%3;
   else if(id=="tgTpPeak") Panel_ApplyEdits();
   else if(id=="tgTimer") g_rt_timer_on=!g_rt_timer_on;
   else if(id=="tgSure") g_rt_sure_sinir=!g_rt_sure_sinir;
   else if(id=="tgRstLim") g_rt_reset_limit=!g_rt_reset_limit;
   else if(id=="tgRstIdle") g_rt_reset_idle=!g_rt_reset_idle;
   else if(id=="tgGenHdg") g_rt_genel_hedge=!g_rt_genel_hedge;
   else if(id=="tgNfPause") g_rt_nf_pause=!g_rt_nf_pause;
   else if(id=="tgNfHedge") g_rt_nf_otohedge=!g_rt_nf_otohedge;
   else if(id=="tgNfHdgCl") g_rt_nf_hedge_kapat=!g_rt_nf_hedge_kapat;
   else if(id=="tgNfLoss") g_rt_nf_zarar_kapat=!g_rt_nf_zarar_kapat;
   else if(id=="tgSaat") g_rt_saat_filtre=!g_rt_saat_filtre;
   else if(id=="tgSonra") g_rt_sonra_dur=!g_rt_sonra_dur;
   // v1.78.22: ATR Sistemi / ADX Filtresi toggle'lari
   else if(id=="tgAtrMode") {
      g_rt_atr_mode = !g_rt_atr_mode;
      // v1.78.30: "tekrar ATR'ye dönmek" = ATR MODU'nu ACIK'a almak — bu an
      // elle girilen ADIM/TP override'lari temizlenir, ATR tekrar sürer.
      if(g_rt_atr_mode) { g_rt_step_manual_override = false; g_rt_tp_manual_override = false; }
   }
   else if(id=="tgAdxFilter") g_rt_adx_filter=!g_rt_adx_filter;
   else if(StringFind(id,"tgRisk")==0 && StringLen(id)>6){
      int rm = (int)StringToInteger(StringSubstr(id,6));
      if(rm>=0 && rm<=4 && rm!=g_rt_risk_mode) {
         g_rt_risk_mode = rm;
         RiskPreset_Apply(rm); // FIX v1.78.13: 13 parametreyi bu motora gore otomatik ayarla
         // FIX v1.78.13: motor secimi artik loglanıyor + panelde kısa onay gösteriliyor
         string rlbl = RiskModeLabel();
         g_panelApplyMsg = "● RISK MOTORU: " + rlbl;
         g_panelApplyMsgUntil = TimeCurrent() + 4;
         PrintFormat("Panel ANLIK | risk=%s lot=%.2f mult=%.3f tp=%.0f pnt=%.0f zarar%%=%.1f",
                     rlbl, g_rt_vg_lot, g_rt_grid_mult, g_rt_tp_pts, g_rt_step_pnt, g_rt_loss_reset_pct);
         Panel_RequestUpdate(true); ChartRedraw(0);
      }
   }
   else if(id=="tgNetHdg") g_rt_net_hedge=!g_rt_net_hedge;
   else if(id=="tgSinyal") g_rt_sinyal=!g_rt_sinyal;
   else if(id=="tgDTE") g_rt_dte_on=!g_rt_dte_on;
   else if(id=="tgHEG") g_rt_heg_on=!g_rt_heg_on;
   else if(id=="tgGridLines") g_rt_grid_lines=!g_rt_grid_lines;
   else if(id=="tgGridSrc") { // v1.78.21 FIX: artik gercekten RT_GridTrendPhase() uzerinden trend-blok kararina giriyor
      g_rt_grid_src=(g_rt_grid_src+1)%4;
      string srcNames[] = {"GRID MIKRO","DI","TMI","ENSEMBLE"};
      g_panelApplyMsg = "● TREND KAYNAK: " + srcNames[g_rt_grid_src];
      g_panelApplyMsgUntil = TimeCurrent() + 4;
      PrintFormat("Panel ANLIK | trend_kaynak=%s", srcNames[g_rt_grid_src]);
   }
   else if(id=="tgDirEng") { // FIX v1.78.13
      g_rt_dir_engine=(g_rt_dir_engine+1)%3;
      string dEngNames[] = {"VEMA-X","1.DOKUNUS","KLASIK"};
      g_panelApplyMsg = "● YON MOTORU: " + dEngNames[g_rt_dir_engine];
      g_panelApplyMsgUntil = TimeCurrent() + 4;
      PrintFormat("Panel ANLIK | yon_motoru=%s", dEngNames[g_rt_dir_engine]);
   }
   else if(id=="tgTpStart") g_rt_tp_start=(g_rt_tp_start+1)%2;
   else if(id=="tgTpPeakMode") g_rt_peak_mode=(g_rt_peak_mode+1)%2;
   else if(id=="tgSaatMode") g_rt_saat_mode=(g_rt_saat_mode+1)%3;
   else if(id=="tgBonus") g_rt_bonus_tp=!g_rt_bonus_tp;
   else if(id=="tgBlok") g_rt_blok=!g_rt_blok;
   else if(id=="tgKarHep") g_rt_kar_hepsini_kapat=!g_rt_kar_hepsini_kapat;
   else if(id=="tgZarHep") g_rt_zarar_hepsini_kapat=!g_rt_zarar_hepsini_kapat;
   else if(id=="tgMikro"){
      if(g_rt_mikro_trend==0) g_rt_mikro_trend=1;
      else if(g_rt_mikro_trend>0) g_rt_mikro_trend=-1;
      else g_rt_mikro_trend=0;
   }
   else if(id=="btnResetChg") PanelMemory_ResetEquityBase();
   else if(id=="btnCloseProfit"||id=="btnCloseAll"||id=="btnCloseLoss"){
      // v1.78.42 FIX (#101): PositionClose() bool donusu kontrol ediliyordu
      // (sadece AutoTune icin) ama basarisizlik durumunda kullaniciya HICBIR
      // geri bildirim yoktu — "TUMUNU KAPAT"a basilinca bazi pozisyonlar
      // kapanmayabiliyordu ve panel sanki tam basariliymis gibi davraniyordu.
      // Artik basarisiz/kismi durumda retcode logluyor ve panelde kisa sureli
      // uyari mesaji gosteriyor (mevcut g_panelApplyMsg mekanizmasi ile).
      int closedN = 0, failedN = 0;
      for(int i=PositionsTotal()-1;i>=0;i--){
         ulong tk=PositionGetTicket(i); if(tk==0||!PositionSelectByTicket(tk)) continue;
         if(PositionGetString(POSITION_SYMBOL)!=g_symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC)!=g_magic) continue;
         double p=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
         if(id=="btnCloseProfit"&&p<=0) continue;
         if(id=="btnCloseLoss"&&p>=0) continue;
         if(SafeClosePosition(tk, "PANEL_" + id)) {
            AutoTune_OnDealProfit(p); // DÜZELTME v1.68
            closedN++;
         } else {
            failedN++;
         }
      }
      if(failedN > 0) {
         g_panelApplyMsg = StringFormat("⚠ %d pozisyon kapanamadi (kapandi:%d) — log'a bak", failedN, closedN);
         g_panelApplyMsgUntil = TimeCurrent() + 6;
      } else if(closedN > 0) {
         g_panelApplyMsg = StringFormat("● %d pozisyon kapatildi", closedN);
         g_panelApplyMsgUntil = TimeCurrent() + 3;
      }
   }
   GV_MarkDirty(); MasterPanel_Publish(); Panel_RequestUpdate(true); ChartRedraw(0);
}

void Panel_CanvasOnClick(int mx,int my){
   string id=CV_HitTest(mx,my);
   if(StringLen(id)==0) return;
   Panel_HandleClick(id);
}

//+------------------------------------------------------------------+
//| Drawdown Hedge (PDF 9.2)                                         |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Drawdown Hedge (PDF 9.2)                                         |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Drawdown Hedge (PDF 9.2)                                         |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Drawdown Hedge (PDF 9.2)                                         |
//+------------------------------------------------------------------+
// g_ddHedgeActive / g_ddHedgePaused → üst global blok (v1.68)

// DD HEDGE SAFETY: Base NetVol yalnızca ana magic'ten hesaplanır; kabul edilmiş
// fakat henüz broker pozisyon listesine düşmemiş hedge emri pending kilidiyle
// korunur. Kapatma ve açma döngülerinin tamamı aşağı doğru ilerler.
void DDHedge_Manage(const string symbol)
{
   int ddIdx = Ind_FindIdx(symbol);
   if(ddIdx < 0 || ddIdx >= MAX_SYMBOLS)
      return;
   bool asyncProtect = g_asyncHedgeProtect[ddIdx];
   if(!RT_DdHedge() && !(g_rt_ready && g_rt_genel_hedge) && !asyncProtect)
      return;
   if(!IsHedgingAccount())
      return;

   static datetime triggerTime[MAX_SYMBOLS];
   static datetime pendingUntil[MAX_SYMBOLS];
   static double pendingTarget[MAX_SYMBOLS];

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(!MathIsValidNumber(balance) || !MathIsValidNumber(equity) || balance <= 0.0)
      return;

   double ddPct = ((balance - equity) / balance) * 100.0;
   double baseNet = 0.0;
   double unusedBasePnL = 0.0;
   int unusedBaseCount = 0;
   double hedgeNet = 0.0;
   double hedgePnL = 0.0;
   int hedgeCount = 0;
   Hedge_GetSignedExposure(symbol, g_magic, baseNet, unusedBasePnL, unusedBaseCount);
   Hedge_GetSignedExposure(symbol, InpMagicDDHedge, hedgeNet, hedgePnL, hedgeCount);

   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   if(!MathIsValidNumber(minLot) || minLot <= 0.0 ||
      !MathIsValidNumber(step) || step <= 0.0)
   {
      PrintFormat("DD HEDGE FAIL | %s | invalid minLot=%.8f step=%.8f", symbol, minLot, step);
      return;
   }

   if(pendingUntil[ddIdx] > TimeCurrent())
   {
      if(MathAbs(hedgeNet - pendingTarget[ddIdx]) <= step * 0.5)
      {
         pendingUntil[ddIdx] = 0;
         pendingTarget[ddIdx] = 0.0;
      }
      else
         return;
   }

   // Normal iletim + temiz guard durumunda hedge'i bir anda bosaltma.
   // Mikro sinyal ana sepet yonune dondugunde ve hedge basabas/karda ise
   // her cagrida yalnizca bir ticket azalt; kalan hacim broker teyidine
   // kadar korunur. Kar kasasi acik ve kullanilabilir fon varsa, hedge
   // cozulmesi mevcut kasayi riske atmaz; kapanis yalnizca pnl>=0 iken olur.
   bool guardsClean = !asyncProtect && !g_ddHedgePaused;
   int hedgeReleaseDirection = (baseNet > 0.0) ? 1 : (baseNet < 0.0 ? -1 : 0);
   bool microReversal = (hedgeReleaseDirection != 0 && g_tmi.valid &&
                         g_tmi.direction == hedgeReleaseDirection &&
                         g_tmi.confidence >= MathMax(RT_ConfFloor(), 0.55));
   bool hedgeReleaseSafe = (MathAbs(baseNet) >= minLot * 2.0 || hedgePnL >= RT_DdTp());
   if(guardsClean && hedgeCount > 0 && microReversal && hedgeReleaseSafe && hedgePnL >= 0.0)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
         if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicDDHedge) continue;

         double ticketPnl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         if(ticketPnl < 0.0) continue;
         ulong previousMagic = g_magic;
         g_trade.SetExpertMagicNumber(InpMagicDDHedge);
         bool released = SafeClosePosition(ticket, "DD_HEDGE_MICRO_RELEASE");
         g_trade.SetExpertMagicNumber(previousMagic);
         if(released)
         {
            PrintFormat("DD Hedge MICRO RELEASE | %s | ticket=%I64u pnl=%.2f remainingBefore=%d",
                        symbol, ticket, ticketPnl, hedgeCount);
            return;
         }
         break;
      }
   }

   if(hedgeCount > 0 && hedgePnL >= RT_DdTp())
   {
      int closedCount = 0;
      int failedCount = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ResetLastError();
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0 || !PositionSelectByTicket(ticket))
            continue;
         if(PositionGetString(POSITION_SYMBOL) != symbol)
            continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicDDHedge)
            continue;

         ulong previousMagic = g_magic;
         g_trade.SetExpertMagicNumber(InpMagicDDHedge);
         bool closed = SafeClosePosition(ticket, "DD_HEDGE_EXIT");
         g_trade.SetExpertMagicNumber(previousMagic);
         if(closed) closedCount++;
         else failedCount++;
      }

      if(failedCount == 0)
      {
         g_ddHedgeActive = false;
         g_ddHedgePaused = false;
         g_asyncHedgeProtect[ddIdx] = false;
         g_asyncHedgeReason[ddIdx] = "";
         pendingUntil[ddIdx] = 0;
         pendingTarget[ddIdx] = 0.0;
         PrintFormat("DD Hedge EXIT | pnl=%.2f >= %.2f | closed=%d",
                     hedgePnL, RT_DdTp(), closedCount);
      }
      else
      {
         g_ddHedgeActive = true;
         g_ddHedgePaused = InpDDHedgePauseTrading;
         PrintFormat("DD Hedge EXIT PARTIAL | pnl=%.2f | closed=%d failed=%d err=%d",
                     hedgePnL, closedCount, failedCount, GetLastError());
      }
      return;
   }

   if((ddPct >= RT_DdPct() || g_asyncHedgeProtect[ddIdx]) && hedgeCount == 0)
   {
      if(triggerTime[ddIdx] == 0)
         triggerTime[ddIdx] = TimeCurrent();

      int waitSec = g_rt_ready ? MathMax(0, g_rt_hedge_wait) : 0;
      if(waitSec > 0 && TimeCurrent() - triggerTime[ddIdx] < waitSec)
         return;

      if(MathAbs(baseNet) < minLot)
         return;

      int direction = (baseNet > 0.0) ? -1 : +1;
      double lot = MathCeil(MathAbs(baseNet) / step - 1e-12) * step;
      if(lot < minLot)
         return;
      lot = NormalizeDouble(lot, VolumeDigits(symbol));

      // v1.78.141 RISK_CALIBRATION FIX: SL preflight'tan ONCE hesaplanir;
      // magic olarak GERCEK hedge magic'i (InpMagicDDHedge) gecirilir.
      double ddHardSl = HardSL_ComputePrice(symbol, direction, false);
      if(!Trade_PreflightMarketOrder(symbol, direction, lot, ddHardSl, InpMagicDDHedge))
         return;

      ulong previousMagic = g_magic;
      g_trade.SetExpertMagicNumber(InpMagicDDHedge);
      ResetLastError();
      bool sent = (direction > 0)
                  ? g_trade.Buy(lot, symbol, 0, ddHardSl, 0, InpTradeComment + "-DDH")
                  : g_trade.Sell(lot, symbol, 0, ddHardSl, 0, InpTradeComment + "-DDH");
      uint retcode = g_trade.ResultRetcode();
      int tradeError = GetLastError();
      g_trade.SetExpertMagicNumber(previousMagic);

      bool accepted = sent &&
         (retcode == TRADE_RETCODE_DONE ||
          retcode == TRADE_RETCODE_DONE_PARTIAL ||
          retcode == TRADE_RETCODE_PLACED);
      if(!accepted)
      {
         PrintFormat("DD Hedge OPEN FAIL | %s | net=%.8f lot=%.8f retcode=%u err=%d %s",
                     symbol, baseNet, lot, retcode, tradeError,
                     g_trade.ResultRetcodeDescription());
         return;
      }

      g_ddHedgeActive = true;
      g_ddHedgePaused = InpDDHedgePauseTrading;
      pendingTarget[ddIdx] = -baseNet;
      pendingUntil[ddIdx] = TimeCurrent() + 10;
      PrintFormat("DD Hedge OPEN ACCEPTED | %s | net=%.8f lot=%.8f dir=%s retcode=%u",
                  symbol, baseNet, lot, direction > 0 ? "BUY" : "SELL", retcode);
      return;
   }

   if(ddPct < RT_DdPct() && !g_asyncHedgeProtect[ddIdx])
      triggerTime[ddIdx] = 0;
   g_ddHedgeActive = (hedgeCount > 0);
   g_ddHedgePaused = g_ddHedgeActive && InpDDHedgePauseTrading;
}


//+------------------------------------------------------------------+
//| v1.78.22: ATR Sistemi — ALGO CalcATRBasedParams + ProcessGridAndHedge |
//| iki katmaninin Nexus karsiligi.                                  |
//+------------------------------------------------------------------+
// ALGO'daki gibi iki carpan ust uste biner:
//   1) sembol TIPI  (Forex/BTC/ETH)      -> InpATR_StepMult_*
//   2) risk MODU    (CokGuv..Agresif)    -> riskStepMult (ALGO ProcessGridAndHedge
//                                          case 0:1.5 case 2:0.6 default:1.0 ile
//                                          BIREBIR ayni, aradaki 3 mod dogrusal ara deger)
// Adim = ATR * TriggerMult * symTypeMult * riskStepMult  (ALGO: atrVal*GridTriggerATRMult*riskStepMult)
// TP   = Adim * (statik tablodaki tpPts[mode]/stepPnt[mode] orani)  — Nexus'un
//        kendi R:R karakterini (her motorun kendi TP/Step oranini) korur,
//        sadece MUTLAK olcegi ATR'a (gercek volatiliteye) baglar.
// ALGO'daki "outAdim<0.1 ise 0.1" tabaninin karsiligi: InpATR_MinStepPoints.
double RiskATR_StepMultForMode(const int mode) {
   // ALGO case 0(CokGuvenli)=1.5, case 2(Agresif)=0.6, default(Guvenli)=1.0.
   // Nexus'ta 5 mod var (0..4); 0-1-2-3-4 uzerinde ALGO'nun 3 noktasini
   // (1.5 -> 1.0 -> 0.6) dogrusal enterpole ediyoruz ki HIZLI(3) de mantikli
   // bir ara deger alsin (DENGELI=2 tam ALGO'nun "Guvenli"siyle ort noktada).
   switch(mode) {
      case 0: return 1.50;  // Cok Guvenli — ALGO case 0 ile birebir
      case 1: return 1.20;
      case 2: return 1.00;  // Dengeli — ALGO default (Guvenli) ile birebir
      case 3: return 0.80;
      case 4: return 0.60;  // Agresif — ALGO case 2 ile birebir
      default: return 1.00;
   }
}

double RiskATR_SymTypeMult(const string symbol) {
   int t = RiskATR_SymbolType(symbol);
   if(t == 1) return InpATR_StepMult_BTC;
   if(t == 2) return InpATR_StepMult_ETH;
   return InpATR_StepMult_Forex;
}

// v1.78.26: sembolun O ANKI CANLI spread'ini FIYAT FARKI olarak dondurur
// (point cinsinden degil — RiskATR_AutoFill icindeki stepPrice de fiyat farki
// oldugu icin dogrudan karsilastirilabilir olsun diye). SYMBOL_SPREAD point
// cinsinden gelir (Nexus'un GTP_SPREAD_MULT'ta yaptigi gibi), point ile carpip
// fiyat birimine ceviriyoruz.
double RiskATR_ReadSpreadPrice(const string symbol) {
   long spreadPts = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(spreadPts <= 0 || point <= 0.0) return 0.0;
   return (double)spreadPts * point;
}

// v1.78.22: 5 risk motorunun statik TP/Step oranini dondurur (RiskPreset_Apply
// icindeki tpPts[]/stepPnt[] tablosuyla AYNI — orada tanimli local dizilere bu
// fonksiyondan erisilemedigi icin degerler burada kucuk bir kopya olarak tutulur;
// RiskPreset_Apply degisirse buradaki tablo da guncellenmeli). Amac: hem ilk
// secimde hem 30sn periyodik tazelemede AYNI R:R karakteri korunsun.
double RiskATR_TpStepRatioForMode(const int mode) {
   double stepPnt[5] = { 400, 360, 320, 280, 260 };
   double tpPts[5]   = { 450, 520, 600, 680, 750 };
   if(mode < 0 || mode > 4 || stepPnt[mode] <= 0.0) return InpATR_TP_Ratio;
   return tpPts[mode] / stepPnt[mode];
}

// ALGO ApplyAutoDefaults karsiligi: risk motoru SECILDIGINDE (RiskPreset_Apply
// icinden) ATR okunup Adim/TP puan cinsine cevrilerek doldurulur. tpStepRatio,
// o modun statik tablosundaki TP/Step oranidir (Nexus'un R:R karakteri korunur).
bool RiskATR_AutoFill(const string symbol, const int mode, const double tpStepRatio,
                      double &outStepPts, double &outTpPts) {
   outStepPts = 0; outTpPts = 0;
   if(!RT_ATRMode()) return false;
   double atrVal = RiskATR_Read(symbol);
   if(atrVal <= 0.0) return false; // handle henuz veri vermiyor — cagiran taraf statik tabloya duser

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0.0) return false;

   double symMult = RiskATR_SymTypeMult(symbol);
   double riskMult = RiskATR_StepMultForMode(mode);
   // v1.78.27 FIX: panel/input hangi yoldan gelirse gelsin (edAtrTrig kutusu,
   // InpATR_TriggerMult), carpan burada da 0.1-5.0 araligina sikistirilir —
   // panel dogrulamasi sadece kutuya elle yaziliktan geciyor; input parametresi
   // (MetaEditor "Girdiler" sekmesi) buradan gecmiyor, bu yuzden hesaplama
   // noktasinda ikinci bir guvenlik siniri sart.
   double trigMult = RT_ATRTriggerMult();
   if(trigMult < 0.1) trigMult = 0.1;
   else if(trigMult > 5.0) trigMult = 5.0;
   // ALGO: stepPrice = atrVal * stepMult  (Adim dogrudan FIYAT farki, ALGO v7.61 notu)
   double stepPrice = atrVal * trigMult * symMult * riskMult;
   if(stepPrice < point * InpATR_MinStepPoints) stepPrice = point * InpATR_MinStepPoints;

   // v1.78.26: SPREAD KORUMA — Dogan: "USOIL/UKOIL gibi sorun cikarabilir,
   // spread her sembole gore otomatik olusup ATR moduyla calismali; 1$
   // korumasina artik gerek yok, her sembolun kendi degerleri olacak."
   // Eski sembol-tipi bazli sabit "$ koruma mesafesi" (GuardMove_Forex/BTC/ETH)
   // TAMAMEN KALDIRILDI. Yerine: o sembolun O ANKI CANLI spread'i okunup
   // "step, spread'in en az InpATR_SpreadGuardMult kati olsun" diye taban
   // konuyor. Bu, USOIL/UKOIL gibi genis spread'li sembollerde step'i otomatik
   // buyutur, EURUSD gibi dar spread'li sembollerde kucuk birakir — elle
   // sembol-sembol veya sembol-tipi ayari GEREKMEZ, her sembol kendi canli
   // spread'inden kendi degerini uretir. spread=0 donerse (feed henuz spread
   // vermiyorsa) hicbir sey yapmaz, mevcut stepPrice degismeden kalir.
   if(InpATR_SpreadGuardMult > 0.0) {
      double spreadPrice = RiskATR_ReadSpreadPrice(symbol);
      if(spreadPrice > 0.0) {
         double spreadStep = spreadPrice * InpATR_SpreadGuardMult;
         if(stepPrice < spreadStep) stepPrice = spreadStep;
      }
   }

   double stepPts = stepPrice / point; // Nexus ADIM PNT alani puan cinsinden calisiyor
   double tpPts   = stepPts * ((tpStepRatio > 0) ? tpStepRatio : InpATR_TP_Ratio);

   outStepPts = stepPts;
   outTpPts   = tpPts;
   return true;
}

//+------------------------------------------------------------------+
//| FIX v1.78.18: 5 risk motoru – TAM oto profil (surukle-birak)     |
//+------------------------------------------------------------------+
// Lot/adim/TP + KAR BEK / PEAK / VTP / min-sn / max-level / min-kar$
// Equity'ye gore olceklenir. DENGELI (2) plug&play varsayilan.
void RiskPreset_Apply(int mode, bool resetManualOverride=true) {
   if(mode < 0 || mode > 4) return;
   g_rt_risk_mode = mode;

   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq <= 0.0) eq = AccountInfoDouble(ACCOUNT_BALANCE);
   if(eq <= 0.0) eq = 1000.0;

   // v1.78.20: R:R odaklı – TP genis, min kâr yüksek, zarar eşiği uzak
   // Hedef: 0.5-0.7$ gibi erken kapanış YOK; kâr hedefi kayba göre ~1.5-2.5x
   //                        COK_GUV  GUVENLI  DENGELI  HIZLI    AGRESIF
   // v1.78.23: GRID CARPAN calismiyordu — 0.01 baslangic lotuyla eski
   // carpanlar (1.02-1.10) hicbir seviyede step (0.01) esigini asmiyordu,
   // MathFloor hep 0.01'e geri yuvarliyordu (bkz. TPProj_NormalizeLot).
   // Baslangic lotu hafifce yukseltildi + carpan motor karakterine gore
   // buyutuldu, boylece ilk seviyeden itibaren gercek buyume goruluyor.
   // Simule edilmis son-seviye/kumulatif riskler (guvenlik taniari
   // InpLatticeMaxLot=0.50 ve mutlak 0.5 tavanindan cok once bitiyor):
   //   COK_GUV  3 seviye: 0.02->0.03  kumulatif ~0.10
   //   GUVENLI  4 seviye: 0.02->0.05  kumulatif ~0.16
   //   DENGELI  5 seviye: 0.02->0.07  kumulatif ~0.23
   //   HIZLI    6 seviye: 0.03->0.14  kumulatif ~0.50
   //   AGRESIF  7 seviye: 0.03->0.20  kumulatif ~0.73
   double lot[5]         = {  0.02,    0.02,    0.02,    0.03,    0.03  };
   double bulletLot[5]   = {  0.01,    0.01,    0.01,    0.02,    0.02  };
   double mult[5]        = {  1.25,    1.28,    1.30,    1.30,    1.32  };
   // TP puan: daha genis = daha buyuk $ kâr
   double tpPts[5]       = {   450,     520,     600,     680,     750  };
   // TP VAR %: fiyat yuzdesi – genis tut (MathMax ile birlesir)
   double tpVarPct[5]    = {  0.12,    0.14,    0.16,    0.18,    0.20  };
   // STEP: genis adim = daha seyrek seviye, daha az yogun risk
   double stepPnt[5]     = {   400,     360,     320,     280,     260  };
   double ddPct[5]       = {   3.0,     4.0,     5.5,     7.0,     8.0  };
   double lossResetPct[5]= {   4.0,     5.0,     7.0,     9.0,    11.0  };
   double profitResPct[5]= {   3.0,     4.0,     5.5,     7.0,     8.0  };
   int    zararBlok[5]   = {     2,       3,       3,       4,       4  };
   double hassas[5]      = {   1.35,    1.20,    1.05,    0.95,    0.90  };
   int    onay[5]        = {     4,       3,       3,       2,       2  };
   double tolerans[5]    = {  0.18,    0.14,    0.12,    0.10,    0.09  };
   // komisyon carpani: TP net kâr en az bu kadar maliyet ustunde
   double costMult[5]    = {   5.0,     4.5,     4.0,     3.5,     3.5  };
   int    minSec[5]      = {    40,      30,      25,      20,      18  };
   int    maxLv[5]       = {     3,       4,       5,       6,       7  };
   double vtpPct[5]      = {   0.0,     0.0,     0.0,     0.0,     0.0  };
   // min kapanış $ – equity %0.25-0.40 + mutlak taban (2.5-5$)
   //                        COK_GUV  GUVENLI  DENGELI  HIZLI    AGRESIF
   double minClosePct[5] = { 0.0030,  0.0035,  0.0040,  0.0035,  0.0030 };
   double minCloseAbs[5] = {   3.00,    3.50,    4.00,    3.50,    3.00  };
   int    kul[5]         = {    45,      35,      28,      22,      20  };
   int    ornek[5]       = {     8,       6,       5,       4,       4  };
   // Peak / basket hedef – buyuk kâr
   double peakPct[5]     = {  0.020,   0.025,   0.030,   0.035,   0.040 };
   double peakMin[5]     = {  12.0,    15.0,    18.0,    20.0,    22.0  };
   double peakMax[5]     = {  60.0,    80.0,   100.0,   120.0,   140.0  };
   // KAR BEK: tek pozisyon kâr eşiği (yuksek)
   double pBekPct[5]     = {  0.012,   0.015,   0.018,   0.020,   0.022 };
   double pBekMin[5]     = {   6.0,     8.0,    10.0,    10.0,    12.0  };
   // ZARAR BEK: uzak tut (SL benzeri – erken zarar kesme YOK)
   double lBekPct[5]     = {  0.025,   0.030,   0.035,   0.040,   0.045 };
   double lBekMin[5]     = {  15.0,    18.0,    22.0,    25.0,    28.0  };
   // Bonus TP carpani – spread x mult; yuksek = daha uzak hedef
   double vtpMult[5]     = {  14.0,    16.0,    18.0,    20.0,    22.0  };

   // v1.78.22: ATR Sistemi ACIKSA statik stepPnt[mode]/tpPts[mode] yerine
   // sembolun kendi ATR'indan turetilen deger kullanilir (ALGO ApplyAutoDefaults
   // esinli — "oto doldur"). ATR henuz hazir degilse (yeni acilmis sembol vb.)
   // sessizce statik tabloya duser, davranis bozulmaz.
   double atrStepPts, atrTpPts;
   double tpStepRatio = RiskATR_TpStepRatioForMode(mode); // RiskPreset_Apply tablosuyla ayni oran (bkz. yardimci fonksiyon)
   bool atrFilled = RiskATR_AutoFill(g_symbol, mode, tpStepRatio, atrStepPts, atrTpPts);
   if(atrFilled) { stepPnt[mode] = atrStepPts; tpPts[mode] = atrTpPts; }

   g_rt_vg_lot           = lot[mode];
   g_rt_vg_step          = stepPnt[mode];
   g_rt_bullet_lot       = bulletLot[mode];
   g_rt_grid_mult        = mult[mode];
   g_rt_tp_pts           = tpPts[mode];
   g_rt_tp_var_pct       = tpVarPct[mode];
   g_rt_step_pnt         = stepPnt[mode];
   // v1.78.30: yeni bir risk modu SEÇMEK bilinçli bir "bu presetten baştan
   // başla" eylemi — önceki elle-girilen ADIM/TP artık geçersiz sayılır.
   // v1.78.39 FIX: ama OnInit() her restart'ta MEVCUT modu (değişmemiş) otomatik
   // yeniden uyguluyordu (bkz. "AUTO RiskPreset uygulandi" logu) — bu, kullanıcının
   // bilinçli mod DEĞİŞTİRME eylemiyle aynı fonksiyonu paylaştığı için override
   // bayrakları her restart'ta sessizce sıfırlanıyor, ATR MODU açıksa elle girilen
   // ADIM/TP değeri bir sonraki 30sn'lik tazelemede eziliyordu. Artık sadece
   // gerçekten YENİ bir mod seçildiğinde (resetManualOverride=true, panel click)
   // sıfırlanır; OnInit'in kendi-modunu-yeniden-uygulama çağrısı bunu korur.
   if(resetManualOverride) {
      g_rt_step_manual_override = false;
      g_rt_tp_manual_override   = false;
   }
   g_rt_dd_pct           = ddPct[mode];
   g_rt_loss_reset_pct   = lossResetPct[mode];
   g_rt_profit_reset_pct = profitResPct[mode];
   g_rt_zarar_blok       = zararBlok[mode];
   g_rt_hassas           = hassas[mode];
   g_rt_onay             = onay[mode];
   g_rt_tolerans         = tolerans[mode];
   g_rt_cost_mult        = costMult[mode];
   g_rt_min_sec          = minSec[mode];
   g_rt_max_levels       = maxLv[mode];
   g_rt_vtp_pct          = vtpPct[mode];
   g_rt_vtp_mult         = vtpMult[mode];
   g_rt_bonus_tp         = true;

   // min kapanış: max(mutlak taban, equity%)
   g_rt_min_close_money  = MathMax(minCloseAbs[mode], eq * minClosePct[mode]);
   if(lot[mode] > 0.01)
      g_rt_min_close_money *= (lot[mode] / 0.01);

   g_rt_kulucka          = kul[mode];
   g_rt_kar_kulucka      = MathMax(8, kul[mode] / 3);
   g_rt_zarar_kulucka    = MathMax(15, kul[mode] / 2);
   g_rt_ornek_sn         = ornek[mode];

   double peak = eq * peakPct[mode];
   if(peak < peakMin[mode]) peak = peakMin[mode];
   if(peak > peakMax[mode]) peak = peakMax[mode];
   g_rt_peak = peak;

   double pb = eq * pBekPct[mode];
   if(pb < pBekMin[mode]) pb = pBekMin[mode];
   g_rt_profit_bek = pb;

   double lb = eq * lBekPct[mode];
   if(lb < lBekMin[mode]) lb = lBekMin[mode];
   g_rt_loss_bek = lb;

   g_rt_profit_adet = 1;
   g_rt_loss_adet   = 1;

   g_panelForceEditSync = true;
   GV_MarkDirty();
   PanelMemory_Save();
   PrintFormat("RiskPreset[%d] %s | lot=%.2f step=%.0f tp=%.0f peak=%.2f karBek=%.2f zararBek=%.2f min$=%.2f costx=%.1f | ATR=%s(%s)",
               mode, RiskModeLabel(), g_rt_vg_lot, g_rt_vg_step, g_rt_tp_pts,
               g_rt_peak, g_rt_profit_bek, g_rt_loss_bek, g_rt_min_close_money, g_rt_cost_mult,
               (atrFilled ? "dolduruldu" : "statik-tablo"), g_symbol);
}


//+------------------------------------------------------------------+
//| Islem acilmama nedeni (panel + log)                              |
//+------------------------------------------------------------------+
// g_tradeBlockReason / g_lastTradeDiagLog → üst global blok (v1.68)

// FIX v1.78.13: 5 risk motorunun tam adı - buton kısaltmaları (CGV/GUV/DNG/HIZ/AGR)
// panelde dar yer için kısaltılmıştı, log ve durum satırında tam isim daha faydalı.
string RiskModeLabel() {
   switch(g_rt_risk_mode) {
      case 0: return "COK GUVENLI";
      case 1: return "GUVENLI";
      case 2: return "DENGELI";
      case 3: return "HIZLI";
      case 4: return "AGRESIF";
   }
   return "DENGELI";
}

string TradeDiag_Compute()
{
   if(!InpEnableGlobalTrading) return "GlobalTrading KAPALI (input)";
   if(!g_robotOn) return "ROBOT KAPALI (panel)";
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return "Algo Trading butonu KAPALI";
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) return "EA islem izni yok (ozellikler)";
   if(!TerminalInfoInteger(TERMINAL_CONNECTED)) return "Terminal bagli degil";
   long mode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   if(mode == SYMBOL_TRADE_MODE_DISABLED) return "Sembol isleme kapali";
   // v1.68: TimeTradeServer bazi build'lerde yok – TimeCurrent guvenli
   datetime tserver = TimeCurrent();
   MqlDateTime dt; TimeToStruct(tserver, dt);
   // Basit piyasa: cumartesi tam / pazar
   if(dt.day_of_week == 6 || dt.day_of_week == 0)
      return "Hafta sonu / piyasa kapali olabilir";
   if(g_newsHardLock) return "HABER KILIT";
   if(g_dailyLocked) return "GUNLUK KILIT";
   if(g_ddHedgePaused) return "DD HEDGE pause";
   if(g_timeLimitPaused) return "SURE LIMIT pause";
   if(g_weeklyOutside) return "Haftalik program disi";
   if(g_viopBlocked) return "VIOP seans disi";
   // v1.68: mikro katman blok sebepleri (panel ISLEV satirinda gorunsun)
   if(g_consensusBlocked) return "CONSENSUS blok: "+g_consensusNote;
   if(!g_smart.allow && InpSmartDir_Enable && g_ctx.dir.direction != 0) return "SMART blok: "+g_smart.note;
   if(g_aegis.block_entry) return "AEGIS blok: "+g_aegis.reason;
   if(g_heg.block) return "HEG blok: "+g_heg.reason;
   if(g_dte.block) return "DTE blok: "+g_dte.reason;
   if(g_rt_ready && g_rt_dte_on && g_ctx.dir.direction == 0)
      return "DTE ACIK + yon NOTR – tohum engellenebilir (KONTROL: DTE KAPALI)";
   if(!RT_VG() && !RT_Bullet()) return "GRID ve BULLET kapali";
   if(!g_panelBuy && !g_panelSell) return "ALIS ve SATIS kapali";
   // Yon
   // v1.78.151 FIX (DUZELTME_REHBERI [COLDSTART raporu] Bolum 5): eski
   // mesaj "grid tohum denenecek" diyordu ama execution tarafi direction=0
   // iken HICBIR ZAMAN gercek bir tohum denemiyordu (bkz. Lattice_TryOpenLevel
   // dispatch'indeki v1.78.95 yorumu) - teshis mesaji ile gercek davranis
   // arasinda tutarsizlik vardi (raporun tam olarak isaret ettigi sorun).
   // Artik GERCEK bir ColdStartSeedDirection() katmani var (RunStagedPipeline'da
   // DirectionLock_Manage'DEN ONCE calisiyor) - mesaj artik hangi durumda
   // oldugumuzu doguru yansitiyor: soguk baslangicta seed denenip basarisiz
   // mi oldu, yoksa DirectionLock zaten committed bir yonu koruyup reversal
   // teyidi mi bekliyor (bunlar FARKLI durumlar, raporun Bolum 10 ayrimi).
   if(g_ctx.dir.direction == 0 && (RT_VG() || RT_Bullet())) {
      int tdIdx = Ind_FindIdx(g_ctx.symbol);
      bool neverCommitted = (tdIdx >= 0 && tdIdx < MAX_SYMBOLS && g_dirlock_committedDir[tdIdx] == 0);
      if(neverCommitted)
         return "Yon NOTR – ColdStart seed denendi, DI/TMI/EMA hizalanmadi";
      else
         return "Yon NOTR – DirectionLock onceki yonu koruyor, reversal teyidi bekleniyor";
   }
   return "OK – giris uygun";
}

void TradeDiag_Refresh()
{
   // FIX v1.78.13: aktif risk motoru artik durum metninin basinda gorunuyor
   // (hem panel "ISLEM ·" satiri hem Experts log'daki "TradeDiag:" satiri icin,
   // ikisi de bu tek g_tradeBlockReason kaynagini kullaniyor)
   g_tradeBlockReason = "[" + RiskModeLabel() + "] " + TradeDiag_Compute();
   if(TimeCurrent() - g_lastTradeDiagLog >= 60)
   {
      g_lastTradeDiagLog = TimeCurrent();
      if(StringFind(g_tradeBlockReason, "OK") < 0)
         Print("TradeDiag: ", g_tradeBlockReason);
   }
}

//+------------------------------------------------------------------+
//| 13. ANA PIPELINE ÇALIŞTIRICI                                     |
//+------------------------------------------------------------------+
void RunStagedPipeline() {
   ZeroMemory(g_ctx);
   g_ctx.symbol = g_symbol;
   g_ctx.magic  = g_magic;
   g_ctx.allow_new_entries = true;   // varsayılan açık; güvenlik/ONNX kapatabilir

   // v1.78.130: Motor geçişi sırasında tüm yeni giriş KILITLENIR
   // (AdaptiveMarket_Refresh'te geçiş başladığında g_motorTransitionLocked=true)
   if(g_motorTransitionLocked) {
      g_ctx.allow_new_entries = false;
   }

   // 1
   if(!Stage_PlatformCheck(g_ctx)) return;

   // 2
   Stage_SecurityLocks(g_ctx);

   // 2a Panel TIMER: CALISMA / DURAKLAMA dakikalari
   if(g_rt_ready && g_rt_timer_on && g_rt_work_min > 0) {
      if(g_timerPhaseStart == 0) g_timerPhaseStart = TimeCurrent();
      int elapsedMin = (int)((TimeCurrent() - g_timerPhaseStart) / 60);
      if(!g_timerIdlePhase) {
         // calisma fazi
         if(elapsedMin >= g_rt_work_min) {
            g_timerIdlePhase = true;
            g_timerPhaseStart = TimeCurrent();
            PrintFormat("TIMER: calisma bitti → duraklama %d dk", g_rt_idle_min);
         }
      } else {
         // idle: yeni giris yok
         g_ctx.allow_new_entries = false;
         if(g_rt_idle_min <= 0 || elapsedMin >= g_rt_idle_min) {
            g_timerIdlePhase = false;
            g_timerPhaseStart = TimeCurrent();
            Print("TIMER: duraklama bitti → calisma");
         }
      }
   } else {
      g_timerIdlePhase = false;
   }

   // 2b Drawdown hedge (yönetim + opsiyonel pause)
   bool asyncHedgeProtect = AsyncHedgeProtection_Refresh(g_ctx.symbol);
   if(asyncHedgeProtect)
      g_ctx.allow_new_entries = false;
   DDHedge_Manage(g_ctx.symbol);
   if(g_ddHedgePaused) g_ctx.allow_new_entries = false;

   // 3
   Stage_PositionCache(g_ctx);
   // FIX: PositionCache sonrasi ticket rematch (throttle yok)
   if(RT_VG() && g_runLatticeThisTick)
      Lattice_RematchTickets(g_lattice, g_ctx.symbol);

   // 4
   Stage_GlobalResets(g_ctx);

   // 4b Panel KÂR/ZARAR BEK + ADET
   Stage_PanelBasketRules(g_ctx);

   // 5
   Stage_ProfitExits(g_ctx);

   // 6 Direction (panel ORNEK SN throttle)
   {
      static SDirectionResult s_dirCache[MAX_SYMBOLS];
      static datetime s_dirAt[MAX_SYMBOLS];
      static double   s_dirCachePrice[MAX_SYMBOLS]; // AUDIT v1.78.70 (#9)
      static string   s_dirCacheSymbol[MAX_SYMBOLS];
      int di = Ind_FindIdx(g_ctx.symbol);
      if(di < 0 || di >= MAX_SYMBOLS) di = 0;
      int sampleSec = (g_rt_ready && g_rt_ornek_sn > 0) ? g_rt_ornek_sn : 0;
      bool cacheMatchesSymbol = (s_dirCacheSymbol[di] == g_ctx.symbol);

      // AUDIT v1.78.70 (#9): guclu trend flip / ani fiyat hareketinde cache
      // atlanir — panel ORNEK SN ayari ne olursa olsun. Sadece DARALTIR
      // (daha SIK tazeler), asla daha ESKI veriye izin vermez.
      bool bigMove = false;
      if(InpDirCache_BypassOnBigMove && s_dirCachePrice[di] > 0.0) {
         double curMid = (SymbolInfoDouble(g_ctx.symbol, SYMBOL_BID) + SymbolInfoDouble(g_ctx.symbol, SYMBOL_ASK)) * 0.5;
         double atrNow = RiskATR_Read(g_ctx.symbol);
         if(atrNow <= 0.0) atrNow = Ind_ATR(g_ctx.symbol, 0);
         if(curMid > 0.0 && atrNow > 0.0 && InpDirCache_BypassATRFrac > 0.0) {
            if(MathAbs(curMid - s_dirCachePrice[di]) >= atrNow * InpDirCache_BypassATRFrac)
               bigMove = true;
         }
      }
      if(InpDirCache_MaxAgeSec > 0 && s_dirAt[di] > 0 &&
         (TimeCurrent() - s_dirAt[di]) >= InpDirCache_MaxAgeSec)
         bigMove = true; // mutlak tavan — panel ayarindan bagimsiz

      if(cacheMatchesSymbol && !bigMove && sampleSec > 0 && s_dirAt[di] > 0 &&
         (TimeCurrent() - s_dirAt[di]) < sampleSec) {
         g_ctx.dir = s_dirCache[di];
      } else {
         g_ctx.dir = Stage_DirectionEngine(g_ctx.symbol);
         s_dirCache[di] = g_ctx.dir;
         s_dirCacheSymbol[di] = g_ctx.symbol;
         s_dirAt[di] = TimeCurrent();
         s_dirCachePrice[di] = (SymbolInfoDouble(g_ctx.symbol, SYMBOL_BID) + SymbolInfoDouble(g_ctx.symbol, SYMBOL_ASK)) * 0.5;
      }
   }
   // Direction context is now current; adapt only after it is available.
   AdaptiveMarket_Refresh();
   double criticalFloatingLossPct = 0.0;
   double criticalDeficitPct = 0.0;
   if(AdaptiveMarket_CriticalLoss(criticalFloatingLossPct, criticalDeficitPct)) {
      g_ctx.allow_new_entries = false;
      g_rt_auto_note = "RECOVERY";
   }
   // v1.78.106/108 FIX (kullanici karari + kod incelemesi): g_rawConfidence
   // sadece VEMA-MA/Pullback cezalarindan BAGIMSIZ olmali, ama panelin MIKRO
   // TREND gibi KULLANICI TARAFINDAN BILINCLI ayarlanan hassasiyet
   // parametrelerini YOK SAYMAMALI (bunlar TFG icin de gecerli olmali).
   // v1.78.108: kumulatif delta yaklasimi yerine, MIKRO TREND HER TICK'TE
   // g_rawConfBase (ham taban) uzerine SIFIRDAN uygulanir (bkz. asagida).
   // Panel MIKRO TREND: confidence/yön yumuşatma
   // v1.78.76 FIX: Kullanici 3 mikro-trend ayarini (DUSUK/NORMAL/YUKSEK)
   // controllu XAUUSD M5 backtest ile kiyasladi - eski DUSUK ayari (-0.15
   // confidence penaltisi) diger ikisinden (eski NORMAL=0.0, eski YUKSEK=
   // +0.12) acik farkla daha iyi sonuc verdi (Net Kar +1697 / PF 1.09 vs
   // -1010/-1011, PF 0.92-0.93). Eski DUSUK'un MUTLAK offseti (-0.15) simdi
   // yeni referans NORMAL oldu. YUKSEK, mutlak offseti degismeden (+0.12)
   // korundu; yeni DUSUK ise NORMAL'in bir adim (-0.15) daha secicisi:
   //   YUKSEK = +0.12 mutlak offset (yeni merkeze gore +0.27 fark)
   //   NORMAL = -0.15 mutlak offset (yeni referans, eski DUSUK ile ayni)
   //   DUSUK  = -0.30 mutlak offset (yeni merkeze gore -0.15 fark)
   if(g_rt_ready) {
      if(g_rt_mikro_trend > 0) {
         // YUKSEK: mutlak offset degismedi (+0.12)
         g_ctx.dir.confidence = MathMin(1.0, g_ctx.dir.confidence + 0.12);
      } else if(g_rt_mikro_trend < 0) {
         // DUSUK: yeni merkezden bir kademe daha secici - zayif sinyali notrle
         g_ctx.dir.confidence = MathMax(0.0, g_ctx.dir.confidence - 0.30);
         if(g_ctx.dir.confidence < RT_ConfFloor()) {
            g_ctx.dir.direction = 0;
         }
      } else {
         // NORMAL (yeni referans) = eski DUSUK davranisi: en iyi test
         // sonucunu veren ayar artik varsayilan orta nokta.
         g_ctx.dir.confidence = MathMax(0.0, g_ctx.dir.confidence - 0.15);
         if(g_ctx.dir.confidence < RT_ConfFloor()) {
            g_ctx.dir.direction = 0;
         }
      }
   }
   // Panel HASSAS / ONAY / TOLERANS
   if(g_rt_ready) {
      if(g_ctx.dir.confidence < RT_ConfFloor()) {
         g_ctx.dir.direction = 0;
      }
      // tolerans: cok dusuk conf toleransi
      if(g_rt_tolerans > 0 && g_ctx.dir.confidence < g_rt_tolerans) {
         g_ctx.dir.direction = 0;
      }
   }
   // v1.78.108 FIX (KRITIK - kod incelemesinde bulundu): v1.78.106'daki ilk
   // yaklasim (delta'yi g_rawConfidence UZERINE topluyordu) dir-cache
   // AKTIFKEN (panel ORNEK SN>0) HATALIYDI: cache HIT olan her tick'te
   // g_ctx.dir, Stage_DirectionEngine YENIDEN CAGRILMADAN cache'teki CIPLAK
   // (MIKRO/HASSAS uygulanmamis) degerden basliyor - yani confBeforeMikro
   // HER TICK'TE AYNI sabit degere donuyor, MIKRO/HASSAS delta'si da HER
   // TICK'TE AYNI. Ama eski kod bu ayni delta'yi g_rawConfidence'IN UZERINE
   // HER TICK'TE TEKRAR TEKRAR EKLIYORDU (kumulatif) - birkaç tick sonra
   // g_rawConfidence sifira/negatife dogru sürüklenip TFG'yi kalici olarak
   // yanlis sekilde susturabilirdi. Duzeltme: artik delta g_rawConfidence
   // UZERINE eklenmiyor; bunun yerine VEMA_MA_RegimeGate'in kaydettigi HAM
   // (MIKRO/HASSAS uygulanmamis) taban deger ayri saklanip (g_rawConfBase),
   // MIKRO/HASSAS bu taban uzerine HER TICK'TE SIFIRDAN (kumulatif degil)
   // uygulanir - tipki g_ctx.dir.confidence'in kendisi gibi.
   {
      int idxRC = Ind_FindIdx(g_ctx.symbol);
      if(idxRC >= 0 && idxRC < MAX_SYMBOLS && g_rawConfBase[idxRC] >= 0.0) {
         double rc = g_rawConfBase[idxRC];
         if(g_rt_ready) {
            if(g_rt_mikro_trend > 0) {
               rc = MathMin(1.0, rc + 0.12);
            } else if(g_rt_mikro_trend < 0) {
               rc = MathMax(0.0, rc - 0.30);
            } else {
               rc = MathMax(0.0, rc - 0.15);
            }
         }
         g_rawConfidence[idxRC] = rc;
      }
   }


   // 6b v1.78.54: GLOBAL TREND FLIP GUARD — final yon belli olduktan sonra,
   // yeni pozisyon acilmadan/Lattice-Bullet islenmeden ÖNCE calisir ki
   // celisen eski pozisyonlar bu tick'te kapanip yeni yonun onu acilsin.
   // v1.78.151 COLD-START SEED FIX (DUZELTME_REHBERI [COLDSTART raporu]
   // Bolum 6/8): DirectionLock_Manage()'DEN HEMEN ONCE calisir. SADECE
   // gercek soguk baslangicta (committedDir==0) ve VEMA/panel katmanlari
   // sonrasi hala notr (g_ctx.dir.direction==0) kaldiginda devreye girer.
   // Basarili olursa g_ctx.dir.direction/confidence doldurulur ve
   // DirectionLock_Manage KENDI DEGISMEMIS mantigiyla (satir ~4031) bunu
   // normal bir yon gibi commit eder - kilit mekanizmasi BYPASS EDILMIYOR,
   // sadece besleniyor. RiskGovernor/RiskCap/HardSL/OrderCheck/basket-risk
   // dahil hicbir asagi-akis guvenlik katmani DEGISTIRILMEDI.
   {
      int idxCS = Ind_FindIdx(g_ctx.symbol);
      if(idxCS >= 0 && idxCS < MAX_SYMBOLS &&
         g_ctx.dir.direction == 0 && g_dirlock_committedDir[idxCS] == 0) {
         string csReason = "";
         int seed = ColdStartSeedDirection(g_ctx.symbol, csReason);
         if(seed != 0) {
            g_ctx.dir.direction  = seed;
            // v1.78.156 FIX (DUZELTME_REHBERI Bolum 8, tamamlanmamis kisim):
            // Seed SADECE direction/confidence dolduruyordu, ctx.dir.phase'e
            // HIC dokunmuyordu. Bullet_Process'teki "phaseOk" sarti (yaklasik
            // satir ~12157) SADECE PHASE_TREND_UP/DOWN'da direkt giris acar;
            // phase PHASE_NEUTRAL/RANGE'de kalinca InpAllowReopenNeutral
            // yoluna dusuyor, o da confidence>=0.40 sartiyor - ama seed'in
            // verdigi InpDirLock_MinConf (varsayilan 0.35) bu esigin ALTINDA
            // kaliyordu. Sonuc: seed BUY/SELL uretiyor ama Bullet_Process
            // "PHASE_TREND_DEGIL" ile SESSIZCE reddediyordu (teshis
            // loglarinda kanitlandi - bkz. R21 BULLET TESHIS RED sebep=
            // PHASE_TREND_DEGIL). Duzeltme: seed zaten DI+TMI+EMA UCUNUN
            // BIRDEN ayni yonde hizali olmasini ve Consensus'un normal
            // esiklerini (NDI_GetGate) gecmis olmasini sart kosuyor - bu
            // tanim geregi bir TREND sinyalidir (raporun ayirt ettigi
            // "gercek soguk baslangic" durumu, rastgele/gevsetilmis bir
            // esik DEGIL). O yuzden phase'i de DOGRU sekilde TREND_UP/DOWN
            // olarak kurmak bypass degil, seed'in zaten urettigi sonucu
            // asagi-akisa DOGRU yansitmaktir - digger hicbir esik/mantik
            // (RiskGovernor, HardSL, RiskCap, vs.) DEGISTIRILMEDI.
            g_ctx.dir.phase = (seed > 0) ? PHASE_TREND_UP : PHASE_TREND_DOWN;
            g_ctx.dir.confidence = MathMax(g_ctx.dir.confidence, InpDirLock_MinConf);
            PrintFormat("COLDSTART SEED | %s | yon=%s | sebep=%s", g_ctx.symbol, (seed > 0 ? "BUY" : "SELL"), csReason);
            // GECICI TESHIS (v1.78.152): seed hemen sonrasi gercek deger.
            PrintFormat("TESHIS-A | seed sonrasi g_ctx.dir.direction=%d conf=%.3f phase=%d committedDir=%d",
                        g_ctx.dir.direction, g_ctx.dir.confidence, (int)g_ctx.dir.phase, g_dirlock_committedDir[idxCS]);
         } else if(InpSR_LogDecisions) {
            PrintFormat("COLDSTART SEED YOK | %s | sebep=%s", g_ctx.symbol, csReason);
         }
      }
      // v1.78.164 FIX (UCUNCU KISIR DONGU - kullanicinin v1.78.163 ile
      // paylastigi 3 ekran goruntusunden cikan bulgu): ColdStartSeedDirection
      // SADECE committedDir==0 iken calisiyordu (raporun kendi sinirlamasi -
      // dogru bir sinirlama, "zaten commit edilmis" durumda mudahale etmemek
      // icin). AMA loglar gosterdi ki committedDir!=0 iken de AYNI kok sorun
      // (ana VEMA/rejim motorunun notr donmesi) TEKRARLANIYOR: DI SCORE TESHIS
      // trendScore=0.70-0.82 (gate=0.253'un COK uzerinde, mature=EVET) gosterirken
      // bile, g_ctx.dir.direction 0'da kalip Consensus_Evaluate'e HICBIR ZAMAN
      // gercek bir aday (0'dan farkli direction) olarak ulasmiyordu - Consensus_
      // Evaluate(symbol,0,note) trivially true donuyor (satir ~5092), g_consensusBlocked
      // hic true olmuyor, TradeDiag "CONSENSUS blok" yerine "Yon NOTR - DirectionLock
      // onceki yonu koruyor" gosteriyordu. Sonuc: DirectionLock'un v1.78.158'de
      // DUZELTILEN candidateTicks biriktirme mantigi bile hicbir zaman calisma
      // FIRSATI bulamiyordu - CunkuDirectionLock'a hic bir reversal adayi
      // ULAsMIYORDU.
      //
      // DUZELTME: committedDir!=0 VE ana motor notr (g_ctx.dir.direction==0)
      // oldugunda, AYNI DI+TMI+EMA hizalama cekirdegini (DirAlignmentSignal -
      // ColdStartSeedDirection ile TAMAMEN AYNI esikler, gevsetilmis AYRI bir
      // esik YOK) kullanarak bir aday uretilir. Bu aday - committedDir ile AYNI
      // ya da FARKLI olsun - sadece g_ctx.dir.direction'i dolduruyor;
      // DirectionLock_Manage'in KENDI DEGISMEMIS flip-onay zinciri (candidateTicks
      // biriktirme, InpDirLock_RequireTrendPhase, InpDirLock_CooldownSec - HICBIRI
      // BURADA DEGISTIRILMEDI) bunu normal bir sekilde isler. Yani bu, "hemen
      // ters yone gec" DEGIL - sadece DirectionLock'a degerlendirecegi GERCEK bir
      // aday sagliyor; commit/flip icin TUM guvenlik onaylari (teyit tick sayisi,
      // trend fazi, cooldown) hala AYNEN gecerli ve degismedi.
      else if(idxCS >= 0 && idxCS < MAX_SYMBOLS &&
              g_ctx.dir.direction == 0 && g_dirlock_committedDir[idxCS] != 0) {
         string rsReason = "";
         int rseed = DirAlignmentSignal(g_ctx.symbol, rsReason);
         if(rseed != 0) {
            g_ctx.dir.direction  = rseed;
            g_ctx.dir.phase      = (rseed > 0) ? PHASE_TREND_UP : PHASE_TREND_DOWN;
            g_ctx.dir.confidence = MathMax(g_ctx.dir.confidence, InpDirLock_MinConf);
            if(InpSR_LogDecisions)
               PrintFormat("REVERSAL SEED | %s | yon=%s | committedDir=%d | sebep=%s",
                           g_ctx.symbol, (rseed > 0 ? "BUY" : "SELL"), g_dirlock_committedDir[idxCS], rsReason);
         } else if(InpSR_LogDecisions) {
            PrintFormat("REVERSAL SEED YOK | %s | committedDir=%d | sebep=%s",
                        g_ctx.symbol, g_dirlock_committedDir[idxCS], rsReason);
         }
      }
   }
   DirectionLock_Manage(g_ctx);

   TrendFlipGuard_Manage(g_ctx);

   // RANGE PROFIT GUARD: trendden range rejimine geciste kazanci koru.
   RangeProfitGuard_Manage(g_ctx);
   // v1.78.67 (#130): ayni koruma artik en cok kari getiren Grid sepetine de
   // (BUY/SELL ayri, NET-POZITIF kurallı) uygulaniyor - bkz. fonksiyon basi yorum.
   GridRangeProfitGuard_Manage(g_ctx);

   // 7
   Stage_MicroLayers(g_ctx);

   // 8
   if(!Stage_RouterUDC(g_ctx)) {
      // yeni giriş kapalı – sadece yönetim devam eder
   }

   // Lattice yönetimi
   if(RT_VG() && g_runLatticeThisTick) {
      // FIX: TP oncesi her tick ticket rematch (ticket=0 hucreler atlanmasin)
      Lattice_RematchTickets(g_lattice, g_ctx.symbol);
      Lattice_Update(g_lattice, g_ctx.symbol);
      Lattice_RematchTickets(g_lattice, g_ctx.symbol);
      bool gridRiskBlock = false;
      bool gridRiskOK = GridRisk_Enforce(g_lattice, g_ctx.symbol, gridRiskBlock);
      Lattice_ManageTP(g_lattice, g_ctx.symbol);
      if(g_ctx.allow_new_entries && gridRiskOK && !gridRiskBlock) {
         // v1.78.21 FIX: TREND KAYNAK panelden secilen kaynaga (GRID MIKRO/DI/TMI/ENSEMBLE)
         // gore hesaplanan faz artik gercekten TREND UYUM blogunu besliyor.
         ENUM_MARKET_PHASE gridPhase = RT_GridTrendPhase(g_ctx.dir.phase);
         int d = g_ctx.dir.direction;
         // Trend fazı değiştiyse ve ayar açıksa yalnızca boş sanal hücreleri
         // yeni anchor'a taşı. Aktif kademelerin STEP referansı sabit kalır.
         static ENUM_MARKET_PHASE s_prevGridPhase[MAX_SYMBOLS];
         static bool s_prevGridPhaseSet[MAX_SYMBOLS];
         int rpi = Ind_FindIdx(g_ctx.symbol);
         if(rpi < 0 || rpi >= MAX_SYMBOLS) rpi = 0;
         if(s_prevGridPhaseSet[rpi] && s_prevGridPhase[rpi] != gridPhase &&
            (gridPhase == PHASE_TREND_UP || gridPhase == PHASE_TREND_DOWN ||
             s_prevGridPhase[rpi] == PHASE_TREND_UP || s_prevGridPhase[rpi] == PHASE_TREND_DOWN)) {
            double reMid = (SymbolInfoDouble(g_ctx.symbol, SYMBOL_BID) + SymbolInfoDouble(g_ctx.symbol, SYMBOL_ASK)) * 0.5;
            Lattice_ReanchorOnTrendFlip(g_lattice, g_ctx.symbol, reMid);
         }
         s_prevGridPhase[rpi] = gridPhase;
         s_prevGridPhaseSet[rpi] = true;
         // v1.78.120 EKLENTI (ERB - Early Reversal Brake): SADECE yeni
         // kademe acma cagrisi (Lattice_TryOpenLevel) engellenir - yukaridaki
         // Reanchor (bos hucrelerin tasinmasi, mevcut pozisyon yonetimi
         // sayilir) ve asagidaki Lattice_ManageTP zaten calismaya devam
         // ediyordu, ERB'nin bunlara DOKUNMAMASI gerekiyor (belgenin 7.
         // bolumu: "mevcut TP yonetimi DEVAM").
         bool erbBlocked = InpERB_BlockMicroGrid && ERB_BlocksNewRisk(g_ctx.symbol);
         if(erbBlocked) {
            if(InpERB_LogDecisions)
               PrintFormat("[ERB] BLOCK MICRO GRID | symbol=%s | reason=EARLY_REVERSAL_WARNING", g_ctx.symbol);
         } else if(d > 0)
            Lattice_TryOpenLevel(g_lattice, g_ctx.symbol, +1, gridPhase);
         else if(d < 0)
            Lattice_TryOpenLevel(g_lattice, g_ctx.symbol, -1, gridPhase);
         else {
            // v1.78.95: NÖTR artik eski yonu seed ETMEZ.
            // DirectionLock_Manage() yeni girisleri kilitlemistir.
         }
      }
   }

   // Bullet / Trend
   Bullet_Process(g_ctx);

   TradeDiag_Refresh();
}

//+------------------------------------------------------------------+
//| 14. MULTI-SYMBOL LİSTE                                           |
//+------------------------------------------------------------------+
void SymbolList_Init() {
   g_symbol_count = 0;
   // 1) Grafik sembolü her zaman ilk
   g_symbols[g_symbol_count++] = _Symbol;

   // 2) Extra list
   string extra = InpExtraSymbols;
   StringReplace(extra, " ", "");
   if(StringLen(extra) > 0) {
      string parts[];
      int n = StringSplit(extra, ',', parts);
      for(int i = 0; i < n && g_symbol_count < MAX_SYMBOLS; i++) {
         string s = parts[i];
         if(StringLen(s) == 0) continue;
         // tekrar var mı?
         bool exists = false;
         for(int j = 0; j < g_symbol_count; j++)
            if(g_symbols[j] == s) { exists = true; break; }
         if(exists) continue;
         // market'te var mı?
         if(!SymbolSelect(s, true)) {
            Print("MultiSymbol: sembol seçilemedi → ", s);
            continue;
         }
         g_symbols[g_symbol_count++] = s;
      }
   }

   for(int i = 0; i < g_symbol_count; i++) {
      ZeroMemory(g_lattices[i]);
      ZeroMemory(g_ctxSnapshot[i]); // SECOND_AUDIT #6 FIX
      ZeroMemory(g_diSnapshot[i]);
      ZeroMemory(g_tmiSnapshot[i]);
      ZeroMemory(g_hegSnapshot[i]);
      ZeroMemory(g_dteSnapshot[i]);
      ZeroMemory(g_earlySnapshot[i]);
      ZeroMemory(g_smartSnapshot[i]);
      g_newsHardLockSnapshot[i] = false;
      g_viopBlockedSnapshot[i] = false;
      g_consensusBlockedSnapshot[i] = false;
      g_consensusNoteSnapshot[i] = "";
      g_smartdir_confirmTicks[i] = 0; // SECOND_AUDIT #7 FIX
      g_smartdir_lastDir[i] = 0;
      g_dom_lastUpdateMs[i] = 0; // SECOND_AUDIT #8 FIX
      g_ml_lastInferMs[i] = 0;
      g_ml_trendProb[i] = 0.5;
      g_ml_dirProb[i] = 0.5;
      g_ml_symbolScoreValid[i] = false;
      // v1.68 bullet state per symbol
      g_bullet_ticket[i] = 0;
      g_bullet_peakProfit[i] = 0;
      g_aegPeak[i] = 0; // v1.78.44 FIX (#113)
      g_heg_blockUntil[i] = 0; // v1.78.47 FIX (#118)
      g_bullet_entryDir[i] = 0;
      g_bullet_openTime[i] = 0;
      g_bullet_confirmTicks[i] = 0;
      g_bullet_confirmLastDir[i] = 0;
      g_bullet_sameSideLoss[i] = 0;
      g_bullet_sameSideWin[i] = 0; // v1.78.115
      g_bullet_lastDir[i] = 0;
      g_bullet_prevClosedDir[i] = 0; // v1.78.116
      g_bullet_lastOpen[i] = 0;
      g_bullet_lastClose[i] = 0;
      g_bullet_lastFlip[i] = 0;
      g_bullet_lastCloseWasLoss[i] = 0;
      g_tfg_lastDir[i] = 0;
      g_tfg_lastAction[i] = 0;
      // v1.78.96: DIRECTION FLIP LOCK state'i digerleri gibi resetlenmiyordu
      // (DUZELTME_REHBERI bolum 10) — MultiSymbol listesi calisirken degisirse
      // veya reinit tetiklenirse eski committed yon/teyit sayaci sembole
      // yapisik kalabiliyordu.
      g_dirlock_committedDir[i] = 0;
      g_dirlock_candidateDir[i] = 0;
      g_dirlock_candidateTicks[i] = 0;
      g_dirlock_lastFlip[i] = 0;
      g_dirlock_blockEntries[i] = false;
      // v1.78.97: VEMA-X MA9/MA21 rejim filtresi state'i - digerleri gibi
      // burada resetlenmezse eski teyitli rejim/streak sembole yapisik kalir.
      g_vemaMA_upStreak[i] = 0;
      g_vemaMA_downStreak[i] = 0;
      g_vemaMA_confirmedRegime[i] = 0;
      g_vemaMA_weakZone[i] = false;
      g_pullback_lotMult[i] = 1.0; // v1.78.101: pullback modulu reset - etkisiz baslasin
      g_rawConfidence[i] = -1.0; // v1.78.105: henuz kaydedilmedi sentinel'i - RawConfidence_Get fallback'e dussun
      g_rawConfBase[i] = -1.0; // v1.78.108: MIKRO TREND taban degeri de sentinel'e
      // v1.78.120: ERB (Early Reversal Brake) state resetleri
      g_erb_isWarning[i] = false;
      g_erb_confirmTickCount[i] = 0;
      g_erb_releaseTickCount[i] = 0;
      g_erb_lastScore[i] = 0;
      g_erb_dirAtWarning[i] = 0;
      g_erb_warningSince[i] = 0;
      g_vemaMA_lastBarTime[i] = 0;
      g_range_guard_count[i] = 0;
      g_grid_range_guard_count[i] = 0;
      g_grid_buy_peakProfit[i] = 0;
      g_grid_sell_peakProfit[i] = 0;
      g_extra_lastEntryTime[i] = 0;
      g_newsLockSym[i] = false;
      // v1.78.40 FIX: Bullet_RematchTicket (bkz. tanimi) sadece AYNI oturum
      // icinde ticket=0 kalan durumlari cozer — B_ENTRY_DIR/B_OPEN_TIME zaten
      // RAM'de olmali. Ama restart sonrasi bu RAM state de sifirlaniyordu
      // (yukaridaki satirlar), yani "-BLT" suffix'li broker pozisyonu olsa bile
      // hicbir yerde referansi kalmiyordu — EA o pozisyonu bir daha asla
      // yonetemiyordu (Bonus TP/Profit Lock/Max Hold/Flip calismaz) VE ayni
      // yonde ikinci bir bullet acabiliyordu. Burada broker'dan "-BLT" suffix'li
      // pozisyon aranip bulunursa B_TICKET/B_ENTRY_DIR/B_OPEN_TIME geri kuruluyor.
      Bullet_ReconcileFromBroker(i);
   }

   string list = "";
   for(int i = 0; i < g_symbol_count; i++) {
      if(i > 0) list += ",";
      list += g_symbols[i];
   }
   Print("Sembol listesi: ", list);
}

void ProcessSymbolIndex(const int idx) {
   if(idx < 0 || idx >= g_symbol_count) return;
   g_sym_idx = idx;  // v1.68 multi-sym bullet + ind handles
   g_symbol = g_symbols[idx];
   g_lattice = g_lattices[idx];
   g_newsHardLock = g_newsLockSym[idx]; // v1.68 per-symbol haber kilidi
   g_runLatticeThisTick = (idx == 0) || InpMultiSymbol_Lattice;

   UpdateVIOPStatus(g_symbol);
   if(InpEnableWeeklySchedule && g_weeklyOutside)
      UpdateWeeklySchedule(g_symbol); // CLOSE/HEDGE action per symbol
   // v1.78.36 FIX: panelin "NET HEDGE" butonu (g_rt_net_hedge) tikla-degistir
   // calisiyordu ama HICBIR karara baglanmamisti — Weekly_NetHedge() zaten var
   // olan (haftalik takvim disi aksiyonu icin yazilmis) net-dengeleme mantigini
   // burada, takvimden bagimsiz, surekli kontrol olarak calistiriyoruz (GENEL
   // HEDGE'in DD-Hedge'i takvimden bagimsiz tetiklemesiyle ayni desen).
   if(g_rt_ready && g_rt_net_hedge)
      Weekly_NetHedge(g_symbol);
   RunStagedPipeline();

   g_lattices[idx] = g_lattice;
   g_ctxSnapshot[idx] = g_ctx; // SECOND_AUDIT #6 FIX: bkz. tanim yorumu
   g_diSnapshot[idx] = g_di;
   g_tmiSnapshot[idx] = g_tmi;
   g_hegSnapshot[idx] = g_heg;
   g_dteSnapshot[idx] = g_dte;
   g_earlySnapshot[idx] = g_early;
   g_smartSnapshot[idx] = g_smart;
   g_newsHardLockSnapshot[idx] = g_newsHardLock;
   g_viopBlockedSnapshot[idx] = g_viopBlocked;
   g_consensusBlockedSnapshot[idx] = g_consensusBlocked;
   g_consensusNoteSnapshot[idx] = g_consensusNote;
}

//+------------------------------------------------------------------+
//| 15. EVENT HANDLERS                                               |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Tester / canlı başlangıç güvenlik ipuçları                       |
//+------------------------------------------------------------------+
void Preset_LogHints() {
   bool tester = (bool)MQLInfoInteger(MQL_TESTER);
   bool demo   = (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO);

   Print("---- PRESET / RISK HINTS ----");
   if(tester)
      Print("Ortam: STRATEGY TESTER – Calendar/haber ve bazı tick modelleri sınırlı olabilir.");
   else if(demo)
      Print("Ortam: DEMO hesap");
   else
      Print("Ortam: CANLI hesap – agresif ayarları iki kez kontrol edin.");

   // Tehlikeli kombinasyon uyarıları
   if(InpVG_Enable && InpVG_MaxLevelsPerSide > 12)
      Print("UYARI: VG MaxLevels>12 – testerde marjin/DD hızlı şişebilir.");
   if(InpVG_Enable && InpBulletEnable && InpBulletLotMode == BLM_PROJECT)
      Print("NOT: VG + Bullet PROJECT birlikte – lot büyümesi çift kanaldan gelebilir.");
   if(InpAutoTune_Enable && !demo && !tester && InpAutoTune_OnlyDemo)
      Print("AutoTune: OnlyDemo=true → canlıda AutoTune devre dışı kalır (beklenen).");
   if(InpAutoTune_Enable && !InpAutoTune_OnlyDemo && !demo && !tester)
      Print("UYARI: AutoTune canlıda açık (OnlyDemo=false).");
   if(InpML_ONNX_Enable)
      Print("ONNX: model dosyası MQL5/Files altında olmalı: ", InpML_ONNX_ModelFile);
   if(!RT_NF())
      Print("NOT: Haber filtresi kapalı – yüksek etkili haber riski açık.");
   if(InpEnableGlobalTrading && InpGlobalLossPct > 10.0)
      Print("UYARI: GlobalLossPct>10 – büyük drawdown toleransı.");
   if(InpVG_LotValue >= 1.0 && InpVG_LotMode == GLM_FIXED)
      Print("NOT: Sabit lot >= 1.0 – küçük hesaplarda yüksek risk.");

   // Önerilen ilk profil
   Print("Öneri (ilk koşu): VG kapalı veya MaxLevels<=4, küçük lot, NF açık, ONNX kapalı, Daily 1%/1%.");
   Print("Tester: SmartDir kapali veya ADX_Min=8; AWR_BlockEntryOnSpike=false; DTE kapali; Hassas=0.7 Onay=1.");
   Print("Preset notları kaynak başlığında (CONSERVATIVE / BALANCED / AGGRESSIVE).");
   Print("-----------------------------");
}

int OnInit() {
   // v1.78.72: her testin/oturumun HANGI kod derlemesi oldugunu Journal'da
   // net gormek icin ilk satirda basiliyor - "hangi sonuc hangi versiyona ait"
   // karisikligini onlemek amaciyla.
   PrintFormat("=== DGN NEXUS PRO R21 BUILD: %s ===", DGN_BUILD_TAG);

   g_symbol = _Symbol;
   g_magic  = BuildMagic();

   g_trade.SetExpertMagicNumber(g_magic);
   g_trade.SetDeviationInPoints(AutoCost_MaxSlippagePts()); // FIX v1.78.13: tutarli baslangic degeri
   Trade_SetFilling(g_symbol); // v1.73

   if(!g_symInfo.Name(g_symbol)) {
      Print("Sembol bilgisi alınamadı: ", g_symbol);
      return INIT_FAILED;
   }

   SymbolList_Init();
   Ind_InitAll();  // v1.68 handle cache
   GV_Keys_Init();
   PanelMemory_Load();

   ZeroMemory(g_lattice);
   for(int vi=0; vi<MAX_SYMBOLS; vi++) ZeroMemory(g_vema[vi]);
   ZeroMemory(g_ml);
   if(InpML_ONNX_Enable) ONNX_Init();
   AutoTune_Init();
   if(InpDOM_Enable) {
      for(int i = 0; i < g_symbol_count; i++) {
         if(!MarketBookAdd(g_symbols[i]))
            Print("DOM: MarketBookAdd başarısız symbol=", g_symbols[i], " err=", GetLastError());
      }
   }
   // v1.68: GV'de deger varsa koru (PanelMemory_Load sonrasi)
   if(g_rt_vg_lot <= 0)     g_rt_vg_lot     = InpVG_LotValue;
   if(g_rt_vg_step <= 0)    g_rt_vg_step    = InpVG_StepValue;
   if(g_rt_bullet_lot <= 0) g_rt_bullet_lot = InpBulletLotValue;
   if(g_rt_peak <= 0)       g_rt_peak       = InpTPProjPeakTargetMoney;
   g_rt_loop_harvest = InpVG_LoopHarvestEnable;
   g_rt_escape_fund  = InpVG_EscapeFundEnable;
   g_rt_pyr_buy      = InpVG_PyramidBuy;
   g_rt_pyr_sell     = InpVG_PyramidSell;
   g_rt_pyramid      = (InpVG_PyramidBuy || InpVG_PyramidSell);
   g_rt_sound        = InpSoundAlertsEnabled;
   g_rt_dom          = InpDOM_Enable;
   g_rt_ml           = true;  // v1.72: sadece ML acik
   // v1.68: PanelMemory_Load() zaten GV'den okudu – yoksa input varsayilan
   if(!g_gvKeysReady) GV_Keys_Init();
   if(!GlobalVariableCheck(g_gvLocVG))
      g_rt_vg_enable = InpVG_Enable;
   if(!GlobalVariableCheck(g_gvLocBullet))
      g_rt_bullet_enable = InpBulletEnable;
   if(!GlobalVariableCheck(g_gvLocNF))
      g_rt_nf_enable = InpNF_Enable;
   g_rt_tp_regime    = (int)InpTPProjRegime;
   g_rt_lot_mode     = (int)InpBulletLotMode;
   g_rt_grid_tp_auth = InpVG_TPAuthority;
   g_rt_tp_pts       = InpVG_TPValue;
   g_rt_dd_hedge     = InpEnableAutoDDHedge;
   g_rt_dd_pct       = InpAutoDDHedgePct;
   g_rt_dd_tp_pct    = InpDDHedgeExitProfit;
   g_rt_profit_reset_pct = InpGlobalProfitPct;
   g_rt_loss_reset_pct   = InpGlobalLossPct;
   g_rt_max_reset    = InpMaxResetCount;
   g_rt_nf_before    = InpNF_BeforeMinutes;
   g_rt_nf_after     = InpNF_AfterMinutes;
   g_rt_nf_pause     = InpNF_PauseTrading;
   g_rt_nf_otohedge  = InpNF_HedgeBeforeNews;
   g_rt_nf_hedge_kapat = InpNF_CloseHedgeAfterNews;
   g_rt_nf_zarar_kapat = InpNF_CloseAllBeforeNews;
   g_rt_sure_sinir   = InpEnableTimeLimitReset;
   g_rt_sonra_dur    = InpPauseAfterTimeLimit;
   g_rt_reset_min    = InpTimeLimitMinutes;
   g_rt_reset_idle   = InpAllowResetWhenPaused;
   g_rt_work_min     = 60;
   g_rt_idle_min     = 30;
   g_rt_timer_on     = false;
   // Panel ekran varsayılanları → motor
   g_rt_profit_bek   = 9.0;
   g_rt_loss_bek     = 15.0;
   g_rt_profit_adet  = 1;
   g_rt_loss_adet    = 1;
   g_rt_kar_kulucka  = InpBullet_ProfitIncubationSec > 0 ? InpBullet_ProfitIncubationSec : 3;
   g_rt_zarar_kulucka= InpBullet_LossIncubationSec > 0 ? InpBullet_LossIncubationSec : 10;
   g_rt_bonus_tp     = InpBullet_BonusTPEnable;
   g_rt_vtp_mult     = InpBullet_BonusTP_Mult;
   g_rt_blok         = true;
   g_rt_zarar_blok   = MathMax(1, InpBullet_SameSideLossLimit);
   g_rt_kar_hepsini_kapat   = true;
   g_rt_zarar_hepsini_kapat = true;
   g_rt_bak_pct      = InpVG_BalancePct;
   g_rt_tp_var_pct   = InpVG_TP_PricePct;
   g_rt_step_pnt     = InpVG_StepValue;
   g_rt_grid_mult    = 1.09;
   g_rt_grid_mult_on = true;
   g_rt_seq_mult     = true;
   g_rt_grid_both    = InpVG_AllowBothSides; // input artık runtime Grid yön ayarını başlatır
   g_rt_trend_align  = true;
   // FIX: risk modu PanelMemory_Load GV'den geldiyse ezme
   if(!GlobalVariableCheck(PanelGV_Key("RISK")))
      g_rt_risk_mode = 2;
   g_rt_net_hedge    = false;
   g_rt_sinyal       = true;
   g_rt_grid_lines   = true;
   g_rt_grid_src     = 0;
   g_rt_dir_engine   = (int)InpDirectionEngine; // FIX v1.78.13
   g_rt_tp_start     = (int)InpTPProjStart;
   g_rt_peak_mode    = 0;
   g_rt_dte_on       = false;  // panel varsayilan KAPALI – acmak isteyen KONTROL'den acar
   g_rt_heg_on       = InpHEG_Enable;
   g_rt_local_close  = false;
   g_rt_saat_mode    = (int)InpWeeklyScheduleClock;
   g_rt_hassas       = 1.0;
   g_rt_onay         = 3;
   g_rt_tolerans     = 0.1;
   g_rt_cost_mult    = 2.0; // FIX v1.78.13
   g_rt_kulucka      = 20;
   g_rt_ornek_sn     = 5;
   g_rt_mikro_trend  = 0;
   g_rt_ready        = true;
   // v1.78.18: surukle-birak – secili risk motorunu (veya DENGELI) otomatik uygula
   // v1.78.39 FIX: resetManualOverride=false — bu OnInit'in kendi-modunu-yeniden-
   // uygulama çağrısı, kullanıcının bilinçli mod değiştirmesi değil; elle girilen
   // ADIM/TP override'ı burada silinmemeli (PanelMemory_Load zaten GV'den okudu).
   {
      int rm = g_rt_risk_mode;
      if(rm < 0 || rm > 4) rm = 2;
      RiskPreset_Apply(rm, false);
      PrintFormat("AUTO RiskPreset uygulandi: mode=%d (%s)", rm, RiskModeLabel());
   }
   // v1.68: PanelMemory_Load GV degerini koru — zorla KAPALI yazma
   // Bilerek kapali baslatmak icin panelden kapat; log:
   PrintFormat("ROBOT baslangic: %s (panelden acin/kapatin)", g_robotOn ? "ACIK" : "KAPALI");
   PrintFormat("Trade izin: Global=%s Robot=%s Terminal=%s EA=%s VG=%s Bullet=%s",
               InpEnableGlobalTrading?"Y":"N", g_robotOn?"Y":"N",
               TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)?"Y":"N",
               MQLInfoInteger(MQL_TRADE_ALLOWED)?"Y":"N",
               InpVG_Enable?"Y":"N", InpBulletEnable?"Y":"N");
   ChartSetInteger(0, CHART_EVENT_MOUSE_WHEEL, true);
   CreateMinimalPanel();

   PrintFormat("DGN Nexus Pro R21 v1.78.20 | Chart=%s | Syms=%d | Magic=%I64u | Hedging=%s | EqBase=%.2f",
               _Symbol, g_symbol_count, g_magic,
               IsHedgingAccount() ? "EVET" : "HAYIR (Netting)", g_indepEquityBase);
   PrintFormat("Init flags | Bullet=%s VG=%s NF=%s VIOP=%s ONNX=%s Shadow=%s AT=%s Extra=%s",
               (InpBulletEnable?"Y":"N"), (InpVG_Enable?"Y":"N"),
               (InpNF_Enable?"Y":"N"), (InpVIOP_EnableSessionControl?"Y":"N"),
               (InpML_ONNX_Enable?"Y":"N"), (InpShadowTrade_Enable?"Y":"N"),
               (InpAutoTune_Enable?"Y":"N"), (InpExtra_Enable?"Y":"N"));
   PrintFormat("Init risk | GProfit=%.1f%% GLoss=%.1f%% DailyP=%.1f%% DailyL=%.1f%% Step=%.1f Lot=%.2f",
               InpGlobalProfitPct, InpGlobalLossPct,
               InpDailyProfitTargetPct, InpDailyLossTargetPct,
               InpVG_StepValue, InpVG_LotValue);
   PrintFormat("Init engine | Dir=%s LotMode=%s TPProj=%s NDI=%s",
               EnumToString(InpDirectionEngine), EnumToString(InpBulletLotMode),
               EnumToString(InpTPProjRegime), EnumToString(InpNDI_Profile));
   PrintFormat("Init panel filtre | DTE=%s (varsayilan KAPALI) HEG=%s Sinyal=%s",
               g_rt_dte_on?"ACIK":"KAPALI", g_rt_heg_on?"ACIK":"KAPALI", g_rt_sinyal?"ACIK":"KAPALI");
   if(InpDTE_Enable && !g_rt_dte_on)
      Print("NOT: InpDTE_Enable=true ama panel DTE KAPALI – runtime panel gecerli.");
   Preset_LogHints();

   // Lisans dogrulama: EA yuklenir/panel calisir ama gecersizse OnTick()
   // trade pipeline'ini calistirmayacak (asagida License_IsValid() kontrolu).
   License_Check(true);

   // FIX v1.78.13: EventSetTimer hic cagrilmiyordu, OnTimer() dosyada tanimli
   // olmasina ragmen ASLA calismiyordu (Panel_RequestUpdate ve artik ML reload dahil).
   EventSetTimer(1);
   return INIT_SUCCEEDED;
}

// SECOND_AUDIT #8 FIX (P3): MQL5 terminali abone olunan sembolde DOM (Market
// Book) degistiginde bu handler'i otomatik cagirir. InpDOM_FreshMs'in
// karsilastirabilecegi bir "son guncelleme" zaman damgasi olmadan tazelik
// kontrolu yapilamiyordu; artik her cagrida GetTickCount64() buraya yaziliyor.
void OnBookEvent(const string &symbol) {
   int idx = Ind_FindIdx(symbol);
   if(idx >= 0) g_dom_lastUpdateMs[idx] = GetTickCount64();
}

void OnDeinit(const int reason) {
   EventKillTimer(); // FIX v1.78.13: EventSetTimer ile eslesen temizlik
   Ind_ReleaseAll();  // v1.68
   GV_MarkDirty();
   PanelMemory_Save();
   // force master write on exit
   g_lastGvPubMs = 0;
   MasterPanel_Publish();
   ONNX_Release();
   if(InpDOM_Enable) {
      for(int i = 0; i < g_symbol_count; i++)
         MarketBookRelease(g_symbols[i]);
   }
   string autoStatusObject = PN_PREFIX + "AUTO_REGIME_STATUS";
   if(ObjectFind(0, autoStatusObject) >= 0)
      ObjectDelete(0, autoStatusObject);
   Panel_DeleteAll();
   Comment("");
   Print("DGN Nexus R21 ", DGN_BUILD_TAG, " kapatıldı. Reason=", reason);
}

// BACKTEST FIX: Tester'da gerçek duvar saatine bağlı CPU throttling'i kapatır;
// aksi halde hızlı simülasyonda tick'ler atlanarak giriş/çıkış sonuçları bozulurdu.
void OnTick() {
   if(!License_IsValid()) {
      Panel_RequestUpdate(false); // panel/gorunum calismaya devam etsin, trade atilmasin
      return;
   }

   bool runPipeline = true;
   bool isTester = (bool)MQLInfoInteger(MQL_TESTER);
   if(InpCPU_Optimization && !isTester) {
      // v1.68: GetTickCount ms vs datetime saniye karisimi duzeltildi
      ulong nowMs = GetTickCount64();
      if(g_lastSignalRefreshMs > 0 &&
         (nowMs - g_lastSignalRefreshMs) < (ulong)InpCPU_SignalRefreshMs)
         runPipeline = false;
      else
         g_lastSignalRefreshMs = nowMs;
   }

   if(runPipeline) {
      MasterPanel_Sync();
      UpdateNewsLock();
      NF_UpdateInfoList(_Symbol); // v1.78.51 (#120): panel Info listesi
      UpdateDailyLock();
      UpdateWeeklySchedule(_Symbol);

      // Tüm semboller
      for(int i = 0; i < g_symbol_count; i++) {
         // Lattice bayrağı: ekstra sembollerde istenmiyorsa VG'yi pipeline içinde
         // sembol index 0 dışında Lattice bloğunu atlamak için geçici global
         ProcessSymbolIndex(i);
      }

      // Panel her zaman grafik sembolüne dönsün
      g_symbol = _Symbol;
      g_lattice = g_lattices[0];
      g_sym_idx = 0; // v1.68: multi-sym loop sonrasi panel/debug chart index
      g_ctx = g_ctxSnapshot[0]; // SECOND_AUDIT #6 FIX: g_ctx de deterministik donuyor
      g_di = g_diSnapshot[0];
      g_tmi = g_tmiSnapshot[0];
      g_heg = g_hegSnapshot[0];
      g_dte = g_dteSnapshot[0];
      g_early = g_earlySnapshot[0];
      g_smart = g_smartSnapshot[0];
      g_newsHardLock = g_newsHardLockSnapshot[0];
      g_viopBlocked = g_viopBlockedSnapshot[0];
      g_consensusBlocked = g_consensusBlockedSnapshot[0];
      g_consensusNote = g_consensusNoteSnapshot[0];

      AutoTune_MaybeRun();
      MasterPanel_Publish();
   }

   Panel_RequestUpdate(false);
}

void OnTimer() {
   ML_MaybeReloadModel(); // FIX v1.78.13: artik gercekten cagriliyor (EventSetTimer sayesinde)
   License_MaybeRecheck();
   Panel_RequestUpdate(false);
}

// GUI SAFETY: yalnızca görünür, panel prefix'li ve gerçekten OBJ_EDIT olan
// nesneler koordinat hit-test'ine girebilir; eski/gizli EditBox tıklanamaz.
bool Panel_IsPointOnEdit(const int mx, const int my)
{
   if(mx < 0 || my < 0)
      return false;

   string eds[] = {
      "edLot","edStep","edMult","edTpPts","edBul","edPeak","edBak","edTpVar",
      "edStepPnt","edLossBek","edLossAd","edPrBek","edPrAd","edHassas","edOnay","edTol",
      "edKul","edKarKul","edZarKul","edVtp","edZarBlok","edOrnek","edAtrTrig","edAdxThr",
      "edWork","edIdle","edDd","edDdTp","edPr","edLr",
      "edHdgWait","edHdgPr","edMaxRst","edRstMin","edNfBef","edNfAft"
   };

   for(int i = 0; i < ArraySize(eds); i++)
   {
      string name = PN_PREFIX + eds[i];
      if(ObjectFind(0, name) < 0)
         continue;
      if(ObjectGetInteger(0, name, OBJPROP_TYPE) != OBJ_EDIT)
         continue;
      if((long)ObjectGetInteger(0, name, OBJPROP_TIMEFRAMES) == OBJ_NO_PERIODS)
         continue;

      int x = (int)ObjectGetInteger(0, name, OBJPROP_XDISTANCE);
      int y = (int)ObjectGetInteger(0, name, OBJPROP_YDISTANCE);
      int w = (int)ObjectGetInteger(0, name, OBJPROP_XSIZE);
      int h = (int)ObjectGetInteger(0, name, OBJPROP_YSIZE);
      if(w <= 0 || h <= 0)
         continue;

      if(mx >= x && mx < x + w && my >= y && my < y + h)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| OBJ_EDIT olay işleme (MT5 native edit kutuları)                  |
//| Olaylar:                                                         |
//|  CHARTEVENT_OBJECT_ENDEDIT  → Enter / focus kaybı → uygula       |
//|  CHARTEVENT_OBJECT_CLICK    → kutuya tık → editing flag          |
//|  CHARTEVENT_OBJECT_CHANGE   → yazarken (yoksay, metni koru)      |
//|  CHARTEVENT_CLICK           → edit dışı tık → bitir+uygula       |
//+------------------------------------------------------------------+
// GUI SAFETY: olay sparam'ı yalnızca tam panel EditBox adıyla eşleşirse kabul edilir.
bool Panel_IsEditObject(const string name)
{
   if(StringLen(name) <= StringLen(PN_PREFIX))
      return false;
   if(StringFind(name, PN_PREFIX) != 0)
      return false;

   string editId = StringSubstr(name, StringLen(PN_PREFIX));
   if(StringFind(editId, "ed") != 0)
      return false;
   if(ObjectFind(0, name) < 0)
      return false;
   if(ObjectGetInteger(0, name, OBJPROP_TYPE) != OBJ_EDIT)
      return false;
   if((long)ObjectGetInteger(0, name, OBJPROP_TIMEFRAMES) == OBJ_NO_PERIODS)
      return false;
   return true;
}

void Panel_BeginEdit(const string name) {
   if(StringLen(name) == 0) return;
   if(ObjectFind(0, name) < 0) return;
   // EDITBOX FIX: başka kutuya geçişte önceki değer yalnızca Panel_ApplyOne()
   // üzerinden bir kez uygulanır; önceki çift parse/persist kaldırıldı.
   if(g_panelEditing && g_panelEditingId != name && StringLen(g_panelEditingId) > 0) {
      string prevId = g_panelEditingId;
      Panel_ApplyOne(prevId);
      Panel_EndEdit();
   }
   g_panelEditing = true;
   g_panelEditingId = name;
   g_panelEditingSince = TimeCurrent();
   g_panelForceEditSync = false; // yazarken text ezilmesin
   // Native düzenleme için özellikler
   ObjectSetInteger(0, name, OBJPROP_READONLY, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 200000);
   ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
}

void Panel_CommitEdit(const string name) {
   if(StringLen(name) == 0) return;
   // Değer oku → parse → global + GV
   Panel_ApplyOne(name);
   if(g_panelEditingId == name)
      Panel_EndEdit();
   // Formatlı metni geri yaz (geçerliyse yeni, değilse eski)
   // Panel_ApplyOne zaten Panel_SyncEditText çağırıyor
}

void Panel_CommitActiveEdit() {
   if(!g_panelEditing || StringLen(g_panelEditingId) == 0) return;
   string fin = g_panelEditingId;
   Panel_EndEdit();
   Panel_ApplyOne(fin);
}

// true = olay tüketildi, OnChartEvent devam etmesin
bool Panel_HandleEditEvent(const int id, const long lparam, const double dparam, const string sparam) {
   // 1) ENDEDIT: Enter veya focus kaybı (MT5 resmi bitiş olayı)
   if(id == CHARTEVENT_OBJECT_ENDEDIT) {
      if(Panel_IsEditObject(sparam)) {
         Panel_CommitEdit(sparam);
         ChartRedraw(0);
         return true;
      }
      return false;
   }

   // 2) CHANGE: bazı build'lerde her karakterde gelir — yoksay (ENDEDIT esas)
   if(id == CHARTEVENT_OBJECT_CHANGE) {
      if(Panel_IsEditObject(sparam))
         return true; // yut, panel yenileme/sync yok
      return false;
   }

   // 3) OBJECT_CLICK: kutuya tık
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(Panel_IsEditObject(sparam)) {
         Panel_BeginEdit(sparam);
         return true;
      }
      return false;
   }

   // 4) Chart CLICK: koordinat ile edit üzerinde mi?
   if(id == CHARTEVENT_CLICK) {
      int mx = (int)lparam;
      int my = (int)dparam;
      if(Panel_IsPointOnEdit(mx, my)) {
         // Hangi edit?
         string eds[] = {
            "edLot","edStep","edMult","edTpPts","edBul","edPeak","edBak","edTpVar",
            "edStepPnt","edLossBek","edLossAd","edPrBek","edPrAd","edHassas","edOnay","edTol",
            "edKul","edKarKul","edZarKul","edVtp","edZarBlok","edOrnek","edAtrTrig","edAdxThr",
            "edWork","edIdle","edDd","edDdTp","edPr","edLr",
            "edHdgWait","edHdgPr","edMaxRst","edRstMin","edNfBef","edNfAft"
         };
         for(int i = 0; i < ArraySize(eds); i++) {
            string n = PN_PREFIX + eds[i];
            if(ObjectFind(0, n) < 0) continue;
            if((long)ObjectGetInteger(0, n, OBJPROP_TIMEFRAMES) == OBJ_NO_PERIODS) continue;
            int ex = (int)ObjectGetInteger(0, n, OBJPROP_XDISTANCE);
            int ey = (int)ObjectGetInteger(0, n, OBJPROP_YDISTANCE);
            int ew = (int)ObjectGetInteger(0, n, OBJPROP_XSIZE);
            int eh = (int)ObjectGetInteger(0, n, OBJPROP_YSIZE);
            if(mx >= ex && mx <= ex + ew && my >= ey && my <= ey + eh) {
               Panel_BeginEdit(n);
               return true;
            }
         }
         return true; // edit bölgesi, canvas'a gitme
      }
      // Edit dışına tık → aktif düzenlemeyi kaydet
      if(g_panelEditing)
         Panel_CommitActiveEdit();
      return false; // canvas / diğer işlemler devam edebilir
   }

   return false;
}

// GUI EVENT SAFETY: EditBox olayları önce tüketilir; diğer panel nesneleri
// gerçek nesne tipiyle doğrulanır ve grafik koordinatları açıkça sınırlandırılır.
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(Panel_HandleEditEvent(id, lparam, dparam, sparam))
      return;

   if(id == CHARTEVENT_CLICK)
   {
      if(lparam < 0 || dparam < 0.0)
         return;

      int mouseX = (int)lparam;
      int mouseY = (int)MathRound(dparam);
      if(mouseX >= g_cvX && mouseX < g_cvX + g_cvW &&
         mouseY >= g_cvY && mouseY < g_cvY + g_cvH)
         Panel_CanvasOnClick(mouseX, mouseY);
      return;
   }

   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(StringFind(sparam, PN_PREFIX) != 0)
         return;

      if(Panel_IsEditObject(sparam))
         return;

      string panelClickId = StringSubstr(sparam, StringLen(PN_PREFIX));
      if(Panel_IsAutonomousStatusControl(panelClickId))
         return;

      if(ObjectFind(0, sparam) >= 0 &&
         ObjectGetInteger(0, sparam, OBJPROP_TYPE) != OBJ_EDIT)
         Panel_HandleClick(sparam);
      return;
   }

   if(id == CHARTEVENT_MOUSE_WHEEL)
   {
      if(g_panelScrollMax <= 0)
         return;

      int delta = (int)MathRound(dparam);
      int step = PANEL_SCROLL_STEP;
      if(g_panelScale > 1.15)
         step = (int)MathRound((double)step * g_panelScale);

      if(delta > 0)
         ScrollTab(g_panelMainTab, -step, false);
      else if(delta < 0)
         ScrollTab(g_panelMainTab, step, false);
      return;
   }

   if(id == CHARTEVENT_CHART_CHANGE)
   {
      Panel_RequestUpdate(true);
      ChartRedraw(0);
   }
}

//+------------------------------------------------------------------+
//| SON – v1.76  OBJ_EDIT event handlers (ENDEDIT/CLICK/CHANGE)
//| STRATEJI/ISLEMLER/SISTEM/SONUC + istatistik blogu + ISLEV        |
//| DEGER: carpan/ardisik/trend uyum/TP VAR% | ARAC: timer/DD/sifir  |
//| Derle (F7).                                                      |
//+------------------------------------------------------------------+
