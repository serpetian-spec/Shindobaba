class_name PathJutsu
extends ClanJutsu
## Efsane Yolları teknikleri (LegendPaths): kanon imza teknikleri, her biri kendi koreografisi ve gerçek oyun etkisiyle.
## Jutsu.execute önce "p_<id>" arar. Yardımcılar ClanJutsu'dan gelir (every, after, hit, st, spike, tether, decoy...).
##   Yılan Yolu: yılanlar kollardan fışkırıp bağlar/çeker, Rashōmon kapıları gerçekten engel olur, Kusanagi 25 m uzar,
##               lanetli mühür aşamaları güç verip can eritir, Yamata'da sekiz baş ayrı ayrı saldırır, Edo Tensei'de ölü ninjalar savaşır.
##   Silah Ustası Yolu: parşömenden gerçek silah yağmuru, zincirle çekme/kancalanma, telli silah fırtınası, demir yelpaze kalkanı,
##               gökten dev topuz, efsanevi Bashōsen'in dört sargısı.

const PSTYLE := {
	"sen_ei_jashu": "two_palm", "jagei_jubaku": "sense", "hebi_bunshin_no_jutsu": "clone", "sen_ei_tajashu": "two_palm",
	"kuchiyose_rashomon": "summon", "kusanagi_kuchi": "breath", "gogyo_fuin": "palm", "sen_ei_ranjashu": "ground",
	"ten_no_juin": "power", "juin_ni_no_dankai": "power", "mandara_no_jin": "breath", "orochimaru_ryu_no_kawarimi_no_jutsu": "power",
	"hakuja_sennin_modo": "power", "kuchiyose_sanju_rashomon": "summon", "yamata_no_jutsu": "power", "kuchiyose_edo_tensei": "summon",
	"sojasosai_no_jutsu": "sense",
	"buki_kuchiyose": "scroll", "tesso_kusari": "throw", "soshoryu": "scroll", "tekkosen": "summon", "ito_buki_arashi": "spin",
	"kuchiyose_tetsuzan": "summon", "bashosen_kaze_no_maki": "two_palm", "bashosen_hi_no_maki": "two_palm",
	"bashosen_rai_no_maki": "two_palm", "bashosen_mizu_no_maki": "two_palm",
	# Şifacı Yolu
	"senpuku": "ground", "shikon_no_jutsu": "summon", "saikan_chushutsu_no_jutsu": "medical", "dokugiri": "breath",
	"ranshinsho": "palm", "chakura_no_mesu": "medical", "in_yu_shometsu": "medical", "sozo_saisei": "power",
	# Sekiz Kapı Yolu
	"omote_renge": "rush", "ura_renge": "rush", "hachimon_tonko_no_jin": "power", "asakujaku": "rush", "hirudora": "two_palm",
	"sekizo": "charge", "yagai": "power",
	# Kâğıt Yolu
	"kami_bunshin": "clone", "kami_chocho": "palm", "kami_tsubasa": "power", "shikigami_no_mai": "spin", "kami_yari": "ground",
	"kami_no_shisha_no_jutsu": "summon", "kami_shuriken": "throw",
	# Akademi / genel
	"gofu_kekkai": "seal", "mizu_bunshin_no_jutsu": "clone", "nan_no_kaizo": "power", "narikawari_no_jutsu": "clone", "sanzengarasu_no_jutsu": "sense", "sly_mind_affect_technique": "sense", "sosai_no_ne": "palm", "soshujin": "throw", "suiken": "rush", "suiton_homatsu_rappa": "breath", "suiton_kokuu_no_jutsu": "breath", "suiton_mizu_shibari": "palm", "suiton_mizu_shuriken": "throw", "suiton_mizuame_nabara": "breath", "suiton_mizurappa": "breath", "suiton_suiben": "palm", "suiton_suidan_no_jutsu": "breath", "suiton_suisandan": "breath", "suiton_takitsubo_no_jutsu": "ground", "suiton_teppodama": "breath", "tsukikage": "rush", "tsutenkyaku": "rush", "uchi_naru_sakura": "power", "water_release_wild_water_wave": "breath", "zankukyokuha": "two_palm", "zessenbaku": "palm", "zessenzan": "palm",
	"futon_hanachiri_mai": "spin", "genjutsu_suzune_bunshin": "sense", "kage_buyo": "rush", "karasu_bunshin_no_jutsu": "clone", "kawazu_kumite": "power", "kawazu_tataki": "rush", "konoha_shofu": "rush", "kumo_ryu_omotegiri": "rush", "kumo_ryu_uragiri": "rush", "kumo_shibari": "palm", "kumo_soka": "palm", "kumogakure_taijutsu_okami_ringu": "spin", "kyomeisen": "palm", "mizuame_teppo": "breath", "nekozume": "rush", "okasho": "rush", "raigeki": "rush", "raigyaku_suihei_choppu": "rush", "raikyu": "palm", "raiton_ikazuchi_unagi": "palm", "raiton_raiju_tsuiga": "palm", "rakanken": "rush", "shikomishindan": "throw", "shishi_rendan": "rush",
	"bubble_clone_technique": "clone", "bubitorappu": "ground", "chakura_kontororu_baku": "palm", "earth_release_rock_shelter": "ground", "fujinheki": "two_palm", "futon_fujin_no_jutsu": "breath", "futon_toppa": "breath", "genjutsu_shibari": "sense", "hayanie": "rush", "jouro_senbon": "throw", "juha_sho": "spin", "kamaitachi_no_jutsu": "spin", "konoha_daisenpu": "rush", "konoha_otoshi": "rush", "kaeru_kaeru_no_jutsu": "palm",
	"doton_renga_no_jutsu": "ground", "doton_sazareishi": "palm", "doton_shinju_zanshu_no_jutsu": "ground", "kasumi_jusha_no_jutsu": "sense", "oboro_bunshin_no_jutsu": "clone", "doton_tobi_tsubute": "ground", "doton_dosekiryu": "ground", "doton_retsudo_tensho": "ground", "futon_reppusho": "palm", "futon_kazekiri_no_jutsu": "palm", "katon_endan": "breath",
	"kage_shuriken_no_jutsu": "throw", "kage_senbon": "throw", "konoha_senpu": "rush", "konoha_reppu": "rush", "dainamikku_entori": "rush",
	"zankuha": "two_palm", "sennen_goroshi": "rush", "kanashibari_no_jutsu": "sense",
	# Kurbağa Bilgesi Yolu
	"gamayudan": "breath", "kebari_senbon": "power", "ranjishigami_no_jutsu": "sense", "hari_jizo": "power",
	"kuchiyose_gamaguchi_shibari": "summon", "katon_gamayu_endan": "breath", "senpo_kawazu_naki": "sense",
}


## Jutsuya özel koreografi (hazırlık "wind" + salınım "rel" pozları, zamanlama, gövde klibi) — CastAnim temel stilin üstüne uygular
const PANIM := {
	"kage_shuriken_no_jutsu": {"base": "throw", "pre": 0.3, "post": 0.35, "clip": "b/OverhandThrow", "wind": {"R": [Vector3(-0.6, 0.6, -0.5), Vector3(-0.2, 0.9, -0.4), Vector3(0.0, 1.0, -0.2)], "L": [Vector3(0.1, 0.45, 0.88), Vector3(-0.0, 0.5, 0.86), Vector3(-0.0, 0.9, 0.4)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "spine": -14.0, "hips_yaw": 35.0}, "rel": {"R": [Vector3(-0.1, -0.35, 0.93), Vector3(0.0, -0.3, 0.95), Vector3(0.0, 0.5, 0.85)], "L": [Vector3(0.35, -0.85, -0.35), Vector3(-0.0, -0.4, 0.9), Vector3(-0.0, 0.2, 0.95)], "fR": [0, 0, 0, 0, 0], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 22.0, "hips_yaw": -25.0}},
	"kage_senbon": {"base": "throw", "pre": 0.18, "post": 0.3, "clip": "idle", "wind": {"R": [Vector3(-0.5, 0.3, 0.8), Vector3(0.6, 0.75, 0.2), Vector3(0.4, 0.9, 0.1)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.0, 1.5, 1.5, 1.5, 0.9], "fL": [0, 0, 0, 0, 0], "neck": -5.0}, "rel": {"R": [Vector3(-0.1, -0.6, 0.8), Vector3(0.8, -0.2, 0.55), Vector3(0.9, -0.1, 0.4)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0, 0, 0, 0, 0], "spine": 10.0, "hips_yaw": -15.0}},
	"kanashibari_no_jutsu": {"base": "sense", "pre": 0.35, "post": 0.4, "wind": {"R": [Vector3(-0.2, -0.4, 0.9), Vector3(0.5, 0.75, 0.4), Vector3(0.2, 0.95, 0.2)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.0, 0.0, 1.5, 1.5, 0.9], "fL": [0, 0, 0, 0, 0], "neck": -12.0}, "rel": {"R": [Vector3(-0.1, 0.45, 0.88), Vector3(0.0, 0.5, 0.86), Vector3(0.0, 0.9, 0.4)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.0, 0.0, 1.5, 1.5, 0.9], "fL": [0, 0, 0, 0, 0], "spine": -4.0, "neck": -6.0}},
	"konoha_senpu": {"base": "rush", "pre": 0.18, "post": 0.4, "spin": -360.0, "wind": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 12.0, "hips_yaw": 40.0, "crouch": 0.6}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "hips_yaw": -300.0}},
	"konoha_reppu": {"base": "rush", "pre": 0.15, "post": 0.4, "clip": "b/Slide", "wind": {"R": [Vector3(-0.4, -0.7, -0.5), Vector3(0.0, -0.3, -0.95), Vector3(0.0, -0.6, -0.8)], "L": [Vector3(0.1, -0.35, 0.93), Vector3(-0.0, -0.3, 0.95), Vector3(-0.0, 0.5, 0.85)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 30.0, "crouch": 0.7}, "rel": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 40.0, "hips_yaw": -60.0, "crouch": 0.95}},
	"dainamikku_entori": {"base": "rush", "pre": 0.2, "post": 0.35, "wind": {"R": [Vector3(-0.4, -0.7, -0.5), Vector3(0.0, -0.3, -0.95), Vector3(0.0, -0.6, -0.8)], "L": [Vector3(0.4, -0.7, -0.5), Vector3(-0.0, -0.3, -0.95), Vector3(-0.0, -0.6, -0.8)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 35.0, "neck": -20.0, "crouch": 0.7}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": -25.0, "neck": -10.0}},
	"zankuha": {"base": "two_palm", "pre": 0.3, "post": 0.45, "wind": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -10.0, "neck": -6.0}, "rel": {"R": [Vector3(-0.08, 0.05, 1.0), Vector3(0.0, 0.05, 1.0), Vector3(0.0, 0.9, 0.45)], "L": [Vector3(0.08, 0.05, 1.0), Vector3(-0.0, 0.05, 1.0), Vector3(-0.0, 0.9, 0.45)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 14.0, "crouch": 0.3}},
	"sennen_goroshi": {"base": "rush", "pre": 0.3, "post": 0.4, "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [0.0, 1.5, 1.5, 1.5, 0.9], "fL": [0.0, 1.5, 1.5, 1.5, 0.9], "spine": 30.0, "crouch": 0.85}, "rel": {"R": [Vector3(-0.2, 0.8, 0.55), Vector3(-0.1, 0.85, 0.5), Vector3(0.0, 0.9, 0.4)], "L": [Vector3(0.2, 0.8, 0.55), Vector3(0.1, 0.85, 0.5), Vector3(-0.0, 0.9, 0.4)], "fR": [0.0, 1.5, 1.5, 1.5, 0.9], "fL": [0.0, 1.5, 1.5, 1.5, 0.9], "spine": -10.0, "crouch": 0.5}},
	"doton_renga_no_jutsu": {"base": "ground", "pre": 0.32, "post": 0.45, "wind": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.15, 0.98, 0.1), Vector3(0.05, 1.0, 0.05), Vector3(-0.0, 1.0, 0.0)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -12.0, "neck": -10.0}, "rel": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.1, -0.35, 0.93), Vector3(-0.0, -0.3, 0.95), Vector3(-0.0, 0.5, 0.85)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 45.0, "crouch": 0.9}},
	"doton_sazareishi": {"base": "palm", "pre": 0.2, "post": 0.35, "wind": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0, 0, 0, 0, 0], "spine": 30.0, "crouch": 0.6}, "rel": {"R": [Vector3(-0.08, 0.05, 1.0), Vector3(0.0, 0.05, 1.0), Vector3(0.0, 0.9, 0.45)], "L": [Vector3(0.4, -0.7, -0.5), Vector3(-0.0, -0.3, -0.95), Vector3(-0.0, -0.6, -0.8)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 10.0, "hips_yaw": -20.0}},
	"doton_shinju_zanshu_no_jutsu": {"base": "ground", "pre": 0.25, "post": 0.3, "wind": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.15, 0.98, 0.1), Vector3(0.05, 1.0, 0.05), Vector3(-0.0, 1.0, 0.0)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0.15, 0.15, 0.15, 0.15, 0.3], "spine": -6.0}, "rel": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.15, -0.55, 0.8), Vector3(-0.0, -0.85, 0.5), Vector3(-0.0, -0.4, 0.9)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 55.0, "neck": -30.0, "crouch": 1.0}},
	"kasumi_jusha_no_jutsu": {"base": "sense", "pre": 0.4, "post": 0.45, "wind": {"R": [Vector3(-0.2, -0.4, 0.9), Vector3(0.5, 0.75, 0.4), Vector3(0.2, 0.95, 0.2)], "L": [Vector3(0.2, -0.4, 0.9), Vector3(-0.5, 0.75, 0.4), Vector3(-0.2, 0.95, 0.2)], "fR": [0.0, 0.0, 1.5, 1.5, 0.9], "fL": [0.0, 0.0, 1.5, 1.5, 0.9], "neck": -8.0}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -8.0, "neck": -14.0}},
	"oboro_bunshin_no_jutsu": {"base": "clone", "pre": 0.25, "post": 0.3, "seal_pose": "Bunshin"},
	"doton_tobi_tsubute": {"base": "ground", "pre": 0.35, "post": 0.45, "wind": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.15, -0.55, 0.8), Vector3(-0.0, -0.85, 0.5), Vector3(-0.0, -0.4, 0.9)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 40.0, "crouch": 0.8}, "rel": {"R": [Vector3(-0.2, 0.8, 0.55), Vector3(-0.1, 0.85, 0.5), Vector3(0.0, 0.9, 0.4)], "L": [Vector3(0.2, 0.8, 0.55), Vector3(0.1, 0.85, 0.5), Vector3(-0.0, 0.9, 0.4)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0.6, 0.6, 0.6, 0.6, 0.4], "spine": -12.0, "neck": -12.0}},
	"doton_dosekiryu": {"base": "ground", "pre": 0.32, "post": 0.5, "wind": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": -10.0}, "rel": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.15, -0.55, 0.8), Vector3(-0.0, -0.85, 0.5), Vector3(-0.0, -0.4, 0.9)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 50.0, "neck": -25.0, "crouch": 1.0}},
	"doton_retsudo_tensho": {"base": "ground", "pre": 0.35, "post": 0.55, "wind": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [0, 0, 0, 0, 0], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": -14.0, "neck": -12.0}, "rel": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.35, -0.85, -0.35), Vector3(-0.0, -0.4, 0.9), Vector3(-0.0, 0.2, 0.95)], "fR": [0, 0, 0, 0, 0], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 58.0, "hips_yaw": -20.0, "crouch": 1.0}},
	"futon_reppusho": {"base": "palm", "pre": 0.25, "post": 0.35, "wind": {"R": [Vector3(-0.4, -0.7, -0.5), Vector3(0.0, -0.3, -0.95), Vector3(0.0, -0.6, -0.8)], "L": [Vector3(0.08, 0.05, 1.0), Vector3(-0.0, 0.05, 1.0), Vector3(-0.0, 0.9, 0.45)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0, 0, 0, 0, 0], "spine": -8.0, "hips_yaw": 25.0}, "rel": {"R": [Vector3(-0.08, 0.05, 1.0), Vector3(0.0, 0.05, 1.0), Vector3(0.0, 0.9, 0.45)], "L": [Vector3(0.4, -0.7, -0.5), Vector3(-0.0, -0.3, -0.95), Vector3(-0.0, -0.6, -0.8)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 16.0, "hips_yaw": -25.0}},
	"futon_kazekiri_no_jutsu": {"base": "palm", "pre": 0.18, "post": 0.35, "clip": "b/Sword_Regular_B", "wind": {"R": [Vector3(-0.85, 0.1, -0.5), Vector3(-0.7, 0.1, -0.7), Vector3(-0.6, 0.1, -0.8)], "L": [Vector3(0.1, 0.45, 0.88), Vector3(-0.0, 0.5, 0.86), Vector3(-0.0, 0.9, 0.4)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0, 0, 0, 0, 0], "spine": -4.0, "hips_yaw": 40.0}, "rel": {"R": [Vector3(-0.1, 0.1, 0.99), Vector3(0.7, 0.1, 0.7), Vector3(0.8, 0.1, 0.6)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0, 0, 0, 0, 0], "spine": 10.0, "hips_yaw": -40.0}},
	"katon_endan": {"base": "breath", "pre": 0.3, "post": 0.4, "wind": {"R": [Vector3(-0.3, -0.5, 0.8), Vector3(0.6, 0.7, 0.35), Vector3(0.3, 0.9, 0.3)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": -18.0, "neck": -14.0}, "rel": {"R": [Vector3(-0.3, -0.5, 0.8), Vector3(0.6, 0.7, 0.35), Vector3(0.3, 0.9, 0.3)], "L": [Vector3(0.4, -0.7, -0.5), Vector3(-0.0, -0.3, -0.95), Vector3(-0.0, -0.6, -0.8)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 20.0, "neck": 10.0}},
	"bubble_clone_technique": {"base": "breath", "pre": 0.3, "post": 0.4, "wind": {"R": [Vector3(-0.3, -0.5, 0.8), Vector3(0.6, 0.7, 0.35), Vector3(0.3, 0.9, 0.3)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": -8.0}, "rel": {"R": [Vector3(-0.1, 0.45, 0.88), Vector3(0.0, 0.5, 0.86), Vector3(0.0, 0.9, 0.4)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 6.0, "neck": -8.0}},
	"bubitorappu": {"base": "ground", "pre": 0.3, "post": 0.4, "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [1.2, 1.2, 1.2, 1.2, 0.7], "crouch": 0.5}, "rel": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "spine": 40.0, "hips_yaw": 30.0, "crouch": 0.85}},
	"chakura_kontororu_baku": {"base": "palm", "pre": 0.3, "post": 0.45, "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0.6, 0.6, 0.6, 0.6, 0.4], "spine": 10.0}, "rel": {"R": [Vector3(-0.08, 0.05, 1.0), Vector3(0.0, 0.05, 1.0), Vector3(0.0, 0.9, 0.45)], "L": [Vector3(0.08, 0.05, 1.0), Vector3(-0.0, 0.05, 1.0), Vector3(-0.0, 0.9, 0.45)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0.6, 0.6, 0.6, 0.6, 0.4], "spine": 12.0}},
	"earth_release_rock_shelter": {"base": "ground", "pre": 0.3, "post": 0.5, "wind": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.15, -0.55, 0.8), Vector3(-0.0, -0.85, 0.5), Vector3(-0.0, -0.4, 0.9)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 48.0, "crouch": 0.9}, "rel": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.15, 0.98, 0.1), Vector3(0.05, 1.0, 0.05), Vector3(-0.0, 1.0, 0.0)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -10.0, "neck": -16.0}},
	"fujinheki": {"base": "power", "pre": 0.25, "post": 0.4, "spin": 360.0, "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "crouch": 0.3}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -8.0, "neck": -8.0}},
	"futon_fujin_no_jutsu": {"base": "breath", "pre": 0.32, "post": 0.5, "wind": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": -20.0, "neck": -16.0}, "rel": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": 24.0, "neck": 12.0}},
	"futon_toppa": {"base": "breath", "pre": 0.38, "post": 0.5, "wind": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.25, -0.55, 0.8), Vector3(-0.75, 0.6, 0.25), Vector3(-0.5, 0.8, 0.3)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0.9, 1.4, 1.4, 1.4, 0.9], "spine": -24.0, "neck": -18.0}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 28.0, "neck": 16.0, "crouch": 0.3}},
	"genjutsu_shibari": {"base": "sense", "pre": 0.35, "post": 0.4, "wind": {"R": [Vector3(-0.2, -0.4, 0.9), Vector3(0.5, 0.75, 0.4), Vector3(0.2, 0.95, 0.2)], "L": [Vector3(0.2, -0.4, 0.9), Vector3(-0.5, 0.75, 0.4), Vector3(-0.2, 0.95, 0.2)], "fR": [0.0, 0.0, 1.5, 1.5, 0.9], "fL": [0.0, 0.0, 1.5, 1.5, 0.9], "neck": -6.0}, "rel": {"R": [Vector3(-0.5, 0.3, 0.8), Vector3(0.6, 0.75, 0.2), Vector3(0.4, 0.9, 0.1)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.0, 0.0, 1.5, 1.5, 0.9], "fL": [0, 0, 0, 0, 0], "neck": -14.0}},
	"hayanie": {"base": "rush", "pre": 0.2, "post": 0.45, "clip": "a/Push", "wind": {"R": [Vector3(-0.15, -0.1, 0.98), Vector3(0.1, -0.1, 0.99), Vector3(0.0, -0.3, 0.95)], "L": [Vector3(0.15, -0.1, 0.98), Vector3(-0.1, -0.1, 0.99), Vector3(-0.0, -0.3, 0.95)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0.6, 0.6, 0.6, 0.6, 0.4], "spine": 20.0, "crouch": 0.4}, "rel": {"R": [Vector3(-0.2, 0.3, 0.93), Vector3(0.0, 0.8, 0.6), Vector3(0.0, 1.0, 0.2)], "L": [Vector3(0.2, 0.3, 0.93), Vector3(-0.0, 0.8, 0.6), Vector3(-0.0, 1.0, 0.2)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [1.2, 1.2, 1.2, 1.2, 0.7], "spine": -30.0, "neck": -20.0}},
	"jouro_senbon": {"base": "throw", "pre": 0.28, "post": 0.4, "wind": {"R": [Vector3(-0.4, -0.7, -0.5), Vector3(0.0, -0.3, -0.95), Vector3(0.0, -0.6, -0.8)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "spine": 10.0, "crouch": 0.3}, "rel": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -20.0, "neck": -30.0}},
	"juha_sho": {"base": "power", "pre": 0.3, "post": 0.6, "spin": 720.0, "wind": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "crouch": 0.4}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -6.0}},
	"kamaitachi_no_jutsu": {"base": "palm", "pre": 0.35, "post": 0.45, "clip": "b/Sword_Regular_C", "wind": {"R": [Vector3(-0.85, 0.1, -0.5), Vector3(-0.7, 0.1, -0.7), Vector3(-0.6, 0.1, -0.8)], "L": [Vector3(0.6, 0.6, -0.5), Vector3(0.2, 0.9, -0.4), Vector3(-0.0, 1.0, -0.2)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "spine": -10.0, "hips_yaw": 60.0}, "rel": {"R": [Vector3(-0.1, 0.1, 0.99), Vector3(0.7, 0.1, 0.7), Vector3(0.8, 0.1, 0.6)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "spine": 18.0, "hips_yaw": -60.0}},
	"konoha_daisenpu": {"base": "rush", "pre": 0.18, "post": 0.5, "spin": -1080.0, "wind": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "crouch": 0.5}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9]}},
	"konoha_otoshi": {"base": "rush", "pre": 0.3, "post": 0.45, "wind": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [0, 0, 0, 0, 0], "spine": 20.0, "crouch": 0.6}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 40.0, "neck": -20.0}},
	"kaeru_kaeru_no_jutsu": {"base": "palm", "pre": 0.35, "post": 0.45, "wind": {"R": [Vector3(-0.2, -0.4, 0.9), Vector3(0.5, 0.75, 0.4), Vector3(0.2, 0.95, 0.2)], "L": [Vector3(0.2, -0.4, 0.9), Vector3(-0.5, 0.75, 0.4), Vector3(-0.2, 0.95, 0.2)], "fR": [0.0, 0.0, 1.5, 1.5, 0.9], "fL": [0.0, 0.0, 1.5, 1.5, 0.9]}, "rel": {"R": [Vector3(-0.1, 0.45, 0.88), Vector3(0.0, 0.5, 0.86), Vector3(0.0, 0.9, 0.4)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.0, 1.5, 1.5, 1.5, 0.9], "fL": [0, 0, 0, 0, 0], "neck": -8.0}},
	"futon_hanachiri_mai": {"base": "spin", "pre": 0.3, "post": 0.5, "spin": 540.0, "wind": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.15, 0.98, 0.1), Vector3(0.05, 1.0, 0.05), Vector3(-0.0, 1.0, 0.0)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0.15, 0.15, 0.15, 0.15, 0.3], "hips_yaw": 30.0}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -8.0}},
	"genjutsu_suzune_bunshin": {"base": "sense", "pre": 0.3, "post": 0.4, "wind": {"R": [Vector3(-0.2, 0.8, 0.55), Vector3(-0.1, 0.85, 0.5), Vector3(0.0, 0.9, 0.4)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "neck": -10.0}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "hips_yaw": 30.0}},
	"kage_buyo": {"base": "rush", "pre": 0.2, "post": 0.45, "wind": {"R": [Vector3(-0.4, -0.7, -0.5), Vector3(0.0, -0.3, -0.95), Vector3(0.0, -0.6, -0.8)], "L": [Vector3(0.4, -0.7, -0.5), Vector3(-0.0, -0.3, -0.95), Vector3(-0.0, -0.6, -0.8)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 30.0, "crouch": 0.8}, "rel": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [0, 0, 0, 0, 0], "spine": -20.0, "neck": -30.0, "crouch": 0.0}},
	"karasu_bunshin_no_jutsu": {"base": "clone", "pre": 0.3, "post": 0.4, "wind": {"R": [Vector3(-0.2, -0.4, 0.9), Vector3(0.5, 0.75, 0.4), Vector3(0.2, 0.95, 0.2)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.0, 0.0, 1.5, 1.5, 0.9], "fL": [0, 0, 0, 0, 0], "neck": -10.0}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -10.0, "neck": -16.0}},
	"kawazu_kumite": {"base": "power", "pre": 0.45, "post": 0.5, "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 15.0, "crouch": 0.65}, "rel": {"R": [Vector3(-0.85, -0.45, 0.1), Vector3(-0.9, -0.3, 0.2), Vector3(-0.9, -0.2, 0.3)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "neck": -12.0, "crouch": 0.5}},
	"kawazu_tataki": {"base": "rush", "pre": 0.3, "post": 0.4, "clip": "a/Punch_Cross", "wind": {"R": [Vector3(-0.35, -0.85, -0.35), Vector3(0.0, -0.4, 0.9), Vector3(0.0, 0.2, 0.95)], "L": [Vector3(0.08, 0.05, 1.0), Vector3(-0.0, 0.05, 1.0), Vector3(-0.0, 0.9, 0.45)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [0, 0, 0, 0, 0], "spine": 15.0, "hips_yaw": 30.0, "crouch": 0.6}, "rel": {"R": [Vector3(-0.08, 0.05, 1.0), Vector3(0.0, 0.05, 1.0), Vector3(0.0, 0.9, 0.45)], "L": [Vector3(0.35, -0.85, -0.35), Vector3(-0.0, -0.4, 0.9), Vector3(-0.0, 0.2, 0.95)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 24.0, "hips_yaw": -35.0}},
	"konoha_shofu": {"base": "rush", "pre": 0.18, "post": 0.4, "wind": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.15, -0.55, 0.8), Vector3(-0.0, -0.85, 0.5), Vector3(-0.0, -0.4, 0.9)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 50.0, "crouch": 1.0}, "rel": {"R": [Vector3(-0.85, -0.45, 0.1), Vector3(-0.9, -0.3, 0.2), Vector3(-0.9, -0.2, 0.3)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -25.0, "neck": -25.0}},
	"kumo_ryu_omotegiri": {"base": "rush", "pre": 0.15, "post": 0.35, "clip": "b/Sword_Regular_A", "wind": {"R": [Vector3(-0.35, -0.85, -0.35), Vector3(0.0, -0.4, 0.9), Vector3(0.0, 0.2, 0.95)], "L": [Vector3(0.35, -0.85, -0.35), Vector3(-0.0, -0.4, 0.9), Vector3(-0.0, 0.2, 0.95)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [1.2, 1.2, 1.2, 1.2, 0.7], "spine": 25.0, "hips_yaw": 35.0, "crouch": 0.7}, "rel": {"R": [Vector3(-0.1, 0.2, 0.98), Vector3(0.8, 0.3, 0.5), Vector3(0.85, 0.4, 0.3)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "spine": 20.0, "hips_yaw": -35.0}},
	"kumo_ryu_uragiri": {"base": "rush", "pre": 0.2, "post": 0.4, "clip": "b/Sword_Regular_C", "wind": {"R": [Vector3(-0.1, -0.6, 0.8), Vector3(0.8, -0.2, 0.55), Vector3(0.9, -0.1, 0.4)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "hips_yaw": -50.0, "crouch": 0.5}, "rel": {"R": [Vector3(-0.85, 0.1, -0.5), Vector3(-0.7, 0.1, -0.7), Vector3(-0.6, 0.1, -0.8)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "spine": 14.0, "hips_yaw": 140.0}},
	"kumo_shibari": {"base": "palm", "pre": 0.2, "post": 0.35, "wind": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0, 0, 0, 0, 0], "spine": -10.0}, "rel": {"R": [Vector3(-0.08, 0.05, 1.0), Vector3(0.0, 0.05, 1.0), Vector3(0.0, 0.9, 0.45)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0, 0, 0, 0, 0], "spine": 10.0}},
	"kumo_soka": {"base": "throw", "pre": 0.3, "post": 0.4, "clip": "idle", "wind": {"R": [Vector3(-0.6, 0.6, -0.5), Vector3(-0.2, 0.9, -0.4), Vector3(0.0, 1.0, -0.2)], "L": [Vector3(0.6, 0.6, -0.5), Vector3(0.2, 0.9, -0.4), Vector3(-0.0, 1.0, -0.2)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0.6, 0.6, 0.6, 0.6, 0.4], "spine": -16.0}, "rel": {"R": [Vector3(-0.1, 0.45, 0.88), Vector3(0.0, 0.5, 0.86), Vector3(0.0, 0.9, 0.4)], "L": [Vector3(0.1, 0.45, 0.88), Vector3(-0.0, 0.5, 0.86), Vector3(-0.0, 0.9, 0.4)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 14.0}},
	"kumogakure_taijutsu_okami_ringu": {"base": "spin", "pre": 0.2, "post": 0.45, "spin": -360.0, "wind": {"R": [Vector3(-0.1, -0.6, 0.8), Vector3(0.8, -0.2, 0.55), Vector3(0.9, -0.1, 0.4)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "crouch": 0.5}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "crouch": 0.4}},
	"kyomeisen": {"base": "rush", "pre": 0.25, "post": 0.35, "clip": "a/Punch_Cross", "wind": {"R": [Vector3(-0.35, -0.85, -0.35), Vector3(0.0, -0.4, 0.9), Vector3(0.0, 0.2, 0.95)], "L": [Vector3(0.08, 0.05, 1.0), Vector3(-0.0, 0.05, 1.0), Vector3(-0.0, 0.9, 0.45)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [0, 0, 0, 0, 0], "hips_yaw": 25.0, "crouch": 0.5}, "rel": {"R": [Vector3(-0.08, 0.05, 1.0), Vector3(0.0, 0.05, 1.0), Vector3(0.0, 0.9, 0.45)], "L": [Vector3(0.35, -0.85, -0.35), Vector3(-0.0, -0.4, 0.9), Vector3(-0.0, 0.2, 0.95)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 20.0, "hips_yaw": -30.0}},
	"mizuame_teppo": {"base": "breath", "pre": 0.3, "post": 0.45, "wind": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": -16.0}, "rel": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [0, 0, 0, 0, 0], "spine": 18.0, "neck": 10.0}},
	"nekozume": {"base": "rush", "pre": 0.2, "post": 0.4, "wind": {"R": [Vector3(-0.2, 0.8, 0.55), Vector3(-0.1, 0.85, 0.5), Vector3(0.0, 0.9, 0.4)], "L": [Vector3(0.2, 0.8, 0.55), Vector3(0.1, 0.85, 0.5), Vector3(-0.0, 0.9, 0.4)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0.6, 0.6, 0.6, 0.6, 0.4], "spine": 20.0, "crouch": 0.5}, "rel": {"R": [Vector3(-0.1, -0.6, 0.8), Vector3(0.8, -0.2, 0.55), Vector3(0.9, -0.1, 0.4)], "L": [Vector3(0.1, -0.6, 0.8), Vector3(-0.8, -0.2, 0.55), Vector3(-0.9, -0.1, 0.4)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0.6, 0.6, 0.6, 0.6, 0.4], "spine": 26.0}},
	"okasho": {"base": "charge", "pre": 0.5, "post": 0.5, "wind": {"R": [Vector3(-0.6, 0.6, -0.5), Vector3(-0.2, 0.9, -0.4), Vector3(0.0, 1.0, -0.2)], "L": [Vector3(0.08, 0.05, 1.0), Vector3(-0.0, 0.05, 1.0), Vector3(-0.0, 0.9, 0.45)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [0, 0, 0, 0, 0], "spine": -20.0, "neck": -15.0, "crouch": 0.2}, "rel": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [0, 0, 0, 0, 0], "spine": 55.0, "neck": -30.0, "crouch": 0.9}},
	"raigeki": {"base": "charge", "pre": 0.45, "post": 0.35, "wind": {"R": [Vector3(-0.35, -0.85, -0.35), Vector3(0.0, -0.4, 0.9), Vector3(0.0, 0.2, 0.95)], "L": [Vector3(0.15, -0.1, 0.98), Vector3(-0.1, -0.1, 0.99), Vector3(-0.0, -0.3, 0.95)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0.6, 0.6, 0.6, 0.6, 0.4], "spine": 20.0, "crouch": 0.4}, "rel": {"R": [Vector3(-0.08, 0.05, 1.0), Vector3(0.0, 0.05, 1.0), Vector3(0.0, 0.9, 0.45)], "L": [Vector3(0.4, -0.7, -0.5), Vector3(-0.0, -0.3, -0.95), Vector3(-0.0, -0.6, -0.8)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 24.0, "hips_yaw": -25.0}},
	"raigyaku_suihei_choppu": {"base": "charge", "pre": 0.35, "post": 0.35, "wind": {"R": [Vector3(-0.85, 0.1, -0.5), Vector3(-0.7, 0.1, -0.7), Vector3(-0.6, 0.1, -0.8)], "L": [Vector3(0.08, 0.05, 1.0), Vector3(-0.0, 0.05, 1.0), Vector3(-0.0, 0.9, 0.45)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0, 0, 0, 0, 0], "hips_yaw": 50.0, "crouch": 0.3}, "rel": {"R": [Vector3(-0.1, 0.1, 0.99), Vector3(0.7, 0.1, 0.7), Vector3(0.8, 0.1, 0.6)], "L": [Vector3(0.35, -0.85, -0.35), Vector3(-0.0, -0.4, 0.9), Vector3(-0.0, 0.2, 0.95)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 14.0, "hips_yaw": -55.0}},
	"raikyu": {"base": "charge", "pre": 0.5, "post": 0.35, "wind": {"R": [Vector3(-0.35, -0.85, -0.35), Vector3(0.0, -0.4, 0.9), Vector3(0.0, 0.2, 0.95)], "L": [Vector3(0.35, -0.85, -0.35), Vector3(-0.0, -0.4, 0.9), Vector3(-0.0, 0.2, 0.95)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0.6, 0.6, 0.6, 0.6, 0.4], "spine": 18.0, "crouch": 0.5}, "rel": {"R": [Vector3(-0.08, 0.05, 1.0), Vector3(0.0, 0.05, 1.0), Vector3(0.0, 0.9, 0.45)], "L": [Vector3(0.08, 0.05, 1.0), Vector3(-0.0, 0.05, 1.0), Vector3(-0.0, 0.9, 0.45)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 12.0}},
	"raiton_ikazuchi_unagi": {"base": "charge", "pre": 0.4, "post": 0.6, "wind": {"R": [Vector3(-0.4, -0.7, -0.5), Vector3(0.0, -0.3, -0.95), Vector3(0.0, -0.6, -0.8)], "L": [Vector3(0.15, -0.1, 0.98), Vector3(-0.1, -0.1, 0.99), Vector3(-0.0, -0.3, 0.95)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0, 0, 0, 0, 0], "hips_yaw": 30.0}, "rel": {"R": [Vector3(-0.1, -0.35, 0.93), Vector3(0.0, -0.3, 0.95), Vector3(0.0, 0.5, 0.85)], "L": [Vector3(0.15, -0.1, 0.98), Vector3(-0.1, -0.1, 0.99), Vector3(-0.0, -0.3, 0.95)], "fR": [0, 0, 0, 0, 0], "fL": [0.6, 0.6, 0.6, 0.6, 0.4], "spine": 12.0, "hips_yaw": -15.0}},
	"raiton_raiju_tsuiga": {"base": "charge", "pre": 0.5, "post": 0.4, "wind": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.35, -0.85, -0.35), Vector3(-0.0, -0.4, 0.9), Vector3(-0.0, 0.2, 0.95)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0, 0, 0, 0, 0], "spine": 40.0, "crouch": 0.85}, "rel": {"R": [Vector3(-0.1, -0.35, 0.93), Vector3(0.0, -0.3, 0.95), Vector3(0.0, 0.5, 0.85)], "L": [Vector3(0.4, -0.7, -0.5), Vector3(-0.0, -0.3, -0.95), Vector3(-0.0, -0.6, -0.8)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 20.0, "crouch": 0.4}},
	"rakanken": {"base": "rush", "pre": 0.25, "post": 0.6, "clip": "a/Punch_Jab", "wind": {"R": [Vector3(-0.35, -0.85, -0.35), Vector3(0.0, -0.4, 0.9), Vector3(0.0, 0.2, 0.95)], "L": [Vector3(0.35, -0.85, -0.35), Vector3(-0.0, -0.4, 0.9), Vector3(-0.0, 0.2, 0.95)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 10.0, "crouch": 0.7}, "rel": {"R": [Vector3(-0.08, 0.05, 1.0), Vector3(0.0, 0.05, 1.0), Vector3(0.0, 0.9, 0.45)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 22.0, "hips_yaw": -20.0}},
	"shikomishindan": {"base": "palm", "pre": 0.15, "post": 0.3, "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [0, 0, 0, 0, 0], "neck": -5.0}, "rel": {"R": [Vector3(-0.2, -0.3, 0.93), Vector3(0.0, 0.1, 1.0), Vector3(0.0, 0.3, 0.95)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [0, 0, 0, 0, 0], "spine": 6.0}},
	"shishi_rendan": {"base": "rush", "pre": 0.2, "post": 0.6, "wind": {"R": [Vector3(-0.4, -0.7, -0.5), Vector3(0.0, -0.3, -0.95), Vector3(0.0, -0.6, -0.8)], "L": [Vector3(0.4, -0.7, -0.5), Vector3(-0.0, -0.3, -0.95), Vector3(-0.0, -0.6, -0.8)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 35.0, "crouch": 0.85}, "rel": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [0, 0, 0, 0, 0], "spine": -30.0, "neck": -35.0}},
	"gofu_kekkai": {"base": "scroll", "pre": 0.4, "post": 0.5, "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [0.0, 0.0, 1.5, 1.5, 0.9], "fL": [0.0, 0.0, 1.5, 1.5, 0.9]}, "rel": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.15, -0.55, 0.8), Vector3(-0.0, -0.85, 0.5), Vector3(-0.0, -0.4, 0.9)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0.15, 0.15, 0.15, 0.15, 0.3], "spine": 45.0, "crouch": 0.8}},
	"mizu_bunshin_no_jutsu": {"base": "clone", "pre": 0.25, "post": 0.3, "seal_pose": "Bunshin"},
	"nan_no_kaizo": {"base": "power", "pre": 0.35, "post": 0.4, "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "crouch": 0.4}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -4.0}},
	"narikawari_no_jutsu": {"base": "flicker", "pre": 0.1, "post": 0.2, "seal_pose": "Tairitsu"},
	"sanzengarasu_no_jutsu": {"base": "sense", "pre": 0.35, "post": 0.45, "wind": {"R": [Vector3(-0.2, -0.4, 0.9), Vector3(0.5, 0.75, 0.4), Vector3(0.2, 0.95, 0.2)], "L": [Vector3(0.2, -0.4, 0.9), Vector3(-0.5, 0.75, 0.4), Vector3(-0.2, 0.95, 0.2)], "fR": [0.0, 0.0, 1.5, 1.5, 0.9], "fL": [0.0, 0.0, 1.5, 1.5, 0.9], "neck": -10.0}, "rel": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -10.0, "neck": -20.0}},
	"sly_mind_affect_technique": {"base": "sense", "pre": 0.35, "post": 0.4, "wind": {"R": [Vector3(-0.5, 0.3, 0.8), Vector3(0.6, 0.75, 0.2), Vector3(0.4, 0.9, 0.1)], "L": [Vector3(0.5, 0.3, 0.8), Vector3(-0.6, 0.75, 0.2), Vector3(-0.4, 0.9, 0.1)], "fR": [0.0, 0.0, 1.5, 1.5, 0.9], "fL": [0.0, 0.0, 1.5, 1.5, 0.9]}, "rel": {"R": [Vector3(-0.1, -0.35, 0.93), Vector3(0.0, -0.3, 0.95), Vector3(0.0, 0.5, 0.85)], "L": [Vector3(0.1, -0.35, 0.93), Vector3(-0.0, -0.3, 0.95), Vector3(-0.0, 0.5, 0.85)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "neck": 6.0}},
	"sosai_no_ne": {"base": "sense", "pre": 0.25, "post": 0.45, "wind": {"R": [Vector3(-0.3, -0.5, 0.8), Vector3(0.6, 0.7, 0.35), Vector3(0.3, 0.9, 0.3)], "L": [Vector3(0.3, -0.5, 0.8), Vector3(-0.6, 0.7, 0.35), Vector3(-0.3, 0.9, 0.3)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0.9, 1.4, 1.4, 1.4, 0.9], "neck": -6.0}, "rel": {"R": [Vector3(-0.3, -0.5, 0.8), Vector3(0.6, 0.7, 0.35), Vector3(0.3, 0.9, 0.3)], "L": [Vector3(0.3, -0.5, 0.8), Vector3(-0.6, 0.7, 0.35), Vector3(-0.3, 0.9, 0.3)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0.9, 1.4, 1.4, 1.4, 0.9], "spine": 8.0, "neck": 4.0}},
	"soshujin": {"base": "scroll", "pre": 0.4, "post": 0.45, "wind": {"R": [Vector3(-0.85, -0.45, 0.1), Vector3(-0.9, -0.3, 0.2), Vector3(-0.9, -0.2, 0.3)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0.6, 0.6, 0.6, 0.6, 0.4], "crouch": 0.3}, "rel": {"R": [Vector3(-0.08, 0.05, 1.0), Vector3(0.0, 0.05, 1.0), Vector3(0.0, 0.9, 0.45)], "L": [Vector3(0.08, 0.05, 1.0), Vector3(-0.0, 0.05, 1.0), Vector3(-0.0, 0.9, 0.45)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0.6, 0.6, 0.6, 0.6, 0.4], "spine": 12.0}},
	"suiken": {"base": "rush", "pre": 0.3, "post": 0.5, "wind": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "spine": -15.0, "hips_yaw": 20.0, "crouch": 0.3}, "rel": {"R": [Vector3(-0.1, -0.35, 0.93), Vector3(0.0, -0.3, 0.95), Vector3(0.0, 0.5, 0.85)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [0, 0, 0, 0, 0], "spine": 30.0, "hips_yaw": -40.0}},
	"suiton_homatsu_rappa": {"base": "breath", "pre": 0.3, "post": 0.5, "wind": {"R": [Vector3(-0.3, -0.5, 0.8), Vector3(0.6, 0.7, 0.35), Vector3(0.3, 0.9, 0.3)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": -12.0}, "rel": {"R": [Vector3(-0.3, -0.5, 0.8), Vector3(0.6, 0.7, 0.35), Vector3(0.3, 0.9, 0.3)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": 18.0, "neck": 8.0}},
	"suiton_kokuu_no_jutsu": {"base": "breath", "pre": 0.35, "post": 0.5, "wind": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": -6.0, "neck": 10.0}, "rel": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -22.0, "neck": -40.0}},
	"suiton_mizu_shibari": {"base": "two_palm", "pre": 0.3, "post": 0.45, "wind": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.15, -0.55, 0.8), Vector3(-0.0, -0.85, 0.5), Vector3(-0.0, -0.4, 0.9)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 30.0, "crouch": 0.6}, "rel": {"R": [Vector3(-0.2, 0.8, 0.55), Vector3(-0.1, 0.85, 0.5), Vector3(0.0, 0.9, 0.4)], "L": [Vector3(0.2, 0.8, 0.55), Vector3(0.1, 0.85, 0.5), Vector3(-0.0, 0.9, 0.4)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0.6, 0.6, 0.6, 0.6, 0.4], "spine": -8.0}},
	"suiton_mizu_shuriken": {"base": "throw", "pre": 0.22, "post": 0.35, "clip": "idle", "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0.6, 0.6, 0.6, 0.6, 0.4]}, "rel": {"R": [Vector3(-0.1, 0.1, 0.99), Vector3(0.7, 0.1, 0.7), Vector3(0.8, 0.1, 0.6)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0, 0, 0, 0, 0], "hips_yaw": -30.0}},
	"suiton_mizuame_nabara": {"base": "breath", "pre": 0.35, "post": 0.5, "wind": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": -10.0}, "rel": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": 34.0, "neck": 20.0, "crouch": 0.3}},
	"suiton_mizurappa": {"base": "breath", "pre": 0.34, "post": 0.5, "wind": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": -20.0, "neck": -14.0}, "rel": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": 22.0, "neck": 10.0}},
	"suiton_suidan_no_jutsu": {"base": "breath", "pre": 0.28, "post": 0.4, "wind": {"R": [Vector3(-0.3, -0.5, 0.8), Vector3(0.6, 0.7, 0.35), Vector3(0.3, 0.9, 0.3)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": -14.0}, "rel": {"R": [Vector3(-0.3, -0.5, 0.8), Vector3(0.6, 0.7, 0.35), Vector3(0.3, 0.9, 0.3)], "L": [Vector3(0.4, -0.7, -0.5), Vector3(-0.0, -0.3, -0.95), Vector3(-0.0, -0.6, -0.8)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": 16.0, "neck": 6.0}},
	"suiton_suisandan": {"base": "breath", "pre": 0.3, "post": 0.7, "wind": {"R": [Vector3(-0.3, -0.5, 0.8), Vector3(0.6, 0.7, 0.35), Vector3(0.3, 0.9, 0.3)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": -12.0}, "rel": {"R": [Vector3(-0.3, -0.5, 0.8), Vector3(0.6, 0.7, 0.35), Vector3(0.3, 0.9, 0.3)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 12.0, "hips_yaw": -20.0}},
	"suiton_takitsubo_no_jutsu": {"base": "ground", "pre": 0.35, "post": 0.5, "wind": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.15, 0.98, 0.1), Vector3(0.05, 1.0, 0.05), Vector3(-0.0, 1.0, 0.0)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -10.0}, "rel": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.15, -0.55, 0.8), Vector3(-0.0, -0.85, 0.5), Vector3(-0.0, -0.4, 0.9)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 45.0, "neck": -10.0, "crouch": 0.9}},
	"suiton_teppodama": {"base": "breath", "pre": 0.45, "post": 0.6, "wind": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.25, -0.55, 0.8), Vector3(-0.75, 0.6, 0.25), Vector3(-0.5, 0.8, 0.3)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0.9, 1.4, 1.4, 1.4, 0.9], "spine": -26.0, "neck": -20.0, "crouch": 0.2}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 30.0, "neck": 14.0, "crouch": 0.35}},
	"suiton_suiben": {"base": "palm", "pre": 0.25, "post": 0.4, "clip": "b/Sword_Regular_B", "wind": {"R": [Vector3(-0.85, 0.1, -0.5), Vector3(-0.7, 0.1, -0.7), Vector3(-0.6, 0.1, -0.8)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "hips_yaw": 45.0}, "rel": {"R": [Vector3(-0.1, 0.1, 0.99), Vector3(0.7, 0.1, 0.7), Vector3(0.8, 0.1, 0.6)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [0, 0, 0, 0, 0], "spine": 10.0, "hips_yaw": -50.0}},
	"tsukikage": {"base": "rush", "pre": 0.25, "post": 0.4, "clip": "b/Sword_Regular_C", "wind": {"R": [Vector3(-0.6, 0.6, -0.5), Vector3(-0.2, 0.9, -0.4), Vector3(0.0, 1.0, -0.2)], "L": [Vector3(0.6, 0.6, -0.5), Vector3(0.2, 0.9, -0.4), Vector3(-0.0, 1.0, -0.2)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [1.2, 1.2, 1.2, 1.2, 0.7], "spine": -16.0, "crouch": 0.2}, "rel": {"R": [Vector3(-0.1, -0.35, 0.93), Vector3(0.0, -0.3, 0.95), Vector3(0.0, 0.5, 0.85)], "L": [Vector3(0.1, -0.35, 0.93), Vector3(-0.0, -0.3, 0.95), Vector3(-0.0, 0.5, 0.85)], "fR": [1.2, 1.2, 1.2, 1.2, 0.7], "fL": [1.2, 1.2, 1.2, 1.2, 0.7], "spine": 30.0, "crouch": 0.4}},
	"tsutenkyaku": {"base": "rush", "pre": 0.3, "post": 0.5, "wind": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 20.0, "crouch": 0.7}, "rel": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.15, 0.98, 0.1), Vector3(0.05, 1.0, 0.05), Vector3(-0.0, 1.0, 0.0)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": -30.0, "neck": -25.0}},
	"uchi_naru_sakura": {"base": "power", "pre": 0.25, "post": 0.4, "wind": {"R": [Vector3(-0.5, 0.3, 0.8), Vector3(0.6, 0.75, 0.2), Vector3(0.4, 0.9, 0.1)], "L": [Vector3(0.5, 0.3, 0.8), Vector3(-0.6, 0.75, 0.2), Vector3(-0.4, 0.9, 0.1)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 20.0, "crouch": 0.3}, "rel": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.15, 0.98, 0.1), Vector3(0.05, 1.0, 0.05), Vector3(-0.0, 1.0, 0.0)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": -20.0, "neck": -30.0}},
	"water_release_wild_water_wave": {"base": "breath", "pre": 0.4, "post": 1.0, "wind": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.25, -0.55, 0.8), Vector3(-0.75, 0.6, 0.25), Vector3(-0.5, 0.8, 0.3)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0.9, 1.4, 1.4, 1.4, 0.9], "spine": -22.0, "neck": -16.0}, "rel": {"R": [Vector3(-0.85, -0.45, 0.1), Vector3(-0.9, -0.3, 0.2), Vector3(-0.9, -0.2, 0.3)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 26.0, "neck": 12.0, "crouch": 0.35}},
	"zankukyokuha": {"base": "two_palm", "pre": 0.4, "post": 0.55, "wind": {"R": [Vector3(-0.4, -0.7, -0.5), Vector3(0.0, -0.3, -0.95), Vector3(0.0, -0.6, -0.8)], "L": [Vector3(0.4, -0.7, -0.5), Vector3(-0.0, -0.3, -0.95), Vector3(-0.0, -0.6, -0.8)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 10.0, "crouch": 0.5}, "rel": {"R": [Vector3(-0.08, 0.05, 1.0), Vector3(0.0, 0.05, 1.0), Vector3(0.0, 0.9, 0.45)], "L": [Vector3(0.08, 0.05, 1.0), Vector3(-0.0, 0.05, 1.0), Vector3(-0.0, 0.9, 0.45)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 18.0, "crouch": 0.45}},
	"zessenbaku": {"base": "breath", "pre": 0.25, "post": 0.6, "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 10.0, "crouch": 0.4}, "rel": {"R": [Vector3(-0.85, -0.45, 0.1), Vector3(-0.9, -0.3, 0.2), Vector3(-0.9, -0.2, 0.3)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 24.0, "neck": 14.0}},
	"zessenzan": {"base": "breath", "pre": 0.2, "post": 0.4, "wind": {"R": [Vector3(-0.85, -0.45, 0.1), Vector3(-0.9, -0.3, 0.2), Vector3(-0.9, -0.2, 0.3)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "crouch": 0.4}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 10.0, "neck": 8.0, "hips_yaw": -40.0}},
	"kami_bunshin": {"base": "clone", "pre": 0.3, "post": 0.35, "spin": 180.0, "wind": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0.15, 0.15, 0.15, 0.15, 0.3], "spine": -6.0}, "rel": {"R": [Vector3(-0.1, 0.45, 0.88), Vector3(0.0, 0.5, 0.86), Vector3(0.0, 0.9, 0.4)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 6.0}},
	"kami_chocho": {"base": "palm", "pre": 0.35, "post": 0.5, "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0.15, 0.15, 0.15, 0.15, 0.3], "neck": -6.0}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -10.0, "neck": -14.0}},
	"kami_tsubasa": {"base": "power", "pre": 0.45, "post": 0.6, "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0.15, 0.15, 0.15, 0.15, 0.3], "spine": 15.0, "crouch": 0.35}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -18.0, "neck": -25.0}},
	"shikigami_no_mai": {"base": "spin", "pre": 0.4, "post": 0.6, "spin": 360.0, "wind": {"R": [Vector3(-0.85, -0.45, 0.1), Vector3(-0.9, -0.3, 0.2), Vector3(-0.9, -0.2, 0.3)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0.15, 0.15, 0.15, 0.15, 0.3]}, "rel": {"R": [Vector3(-0.2, 0.8, 0.55), Vector3(-0.1, 0.85, 0.5), Vector3(0.0, 0.9, 0.4)], "L": [Vector3(0.2, 0.8, 0.55), Vector3(0.1, 0.85, 0.5), Vector3(-0.0, 0.9, 0.4)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -10.0}},
	"kami_yari": {"base": "ground", "pre": 0.32, "post": 0.5, "wind": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0, 0, 0, 0, 0], "spine": -10.0}, "rel": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.35, -0.85, -0.35), Vector3(-0.0, -0.4, 0.9), Vector3(-0.0, 0.2, 0.95)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 45.0, "crouch": 0.9}},
	"kami_no_shisha_no_jutsu": {"base": "summon", "pre": 0.7, "post": 1.0, "wind": {"R": [Vector3(-0.2, -0.4, 0.9), Vector3(0.5, 0.75, 0.4), Vector3(0.2, 0.95, 0.2)], "L": [Vector3(0.2, -0.4, 0.9), Vector3(-0.5, 0.75, 0.4), Vector3(-0.2, 0.95, 0.2)], "fR": [0.0, 0.0, 1.5, 1.5, 0.9], "fL": [0.0, 0.0, 1.5, 1.5, 0.9], "neck": -10.0}, "rel": {"R": [Vector3(-0.15, 0.98, 0.1), Vector3(-0.05, 1.0, 0.05), Vector3(0.0, 1.0, 0.0)], "L": [Vector3(0.15, 0.98, 0.1), Vector3(0.05, 1.0, 0.05), Vector3(-0.0, 1.0, 0.0)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -20.0, "neck": -35.0}},
	"kami_shuriken": {"base": "throw", "pre": 0.2, "post": 0.35, "clip": "idle", "wind": {"R": [Vector3(-0.1, -0.6, 0.8), Vector3(0.8, -0.2, 0.55), Vector3(0.9, -0.1, 0.4)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0, 0, 0, 0, 0], "hips_yaw": -30.0}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.25, -0.96, -0.05), Vector3(0.1, -0.97, 0.2), Vector3(-0.0, -1.0, 0.1)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0, 0, 0, 0, 0], "hips_yaw": 35.0}},
	"gamayudan": {"base": "breath", "pre": 0.35, "post": 0.5, "wind": {"R": [Vector3(-0.25, -0.55, 0.8), Vector3(0.75, 0.6, 0.25), Vector3(0.5, 0.8, 0.3)], "L": [Vector3(0.25, -0.55, 0.8), Vector3(-0.75, 0.6, 0.25), Vector3(-0.5, 0.8, 0.3)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0.9, 1.4, 1.4, 1.4, 0.9], "spine": -22.0, "neck": -15.0, "crouch": 0.2}, "rel": {"R": [Vector3(-0.85, -0.45, 0.1), Vector3(-0.9, -0.3, 0.2), Vector3(-0.9, -0.2, 0.3)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": 28.0, "neck": 14.0, "crouch": 0.35}},
	"kebari_senbon": {"base": "power", "pre": 0.35, "post": 0.5, "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 40.0, "neck": -30.0, "crouch": 0.6}, "rel": {"R": [Vector3(-0.9, 0.4, 0.15), Vector3(-0.9, 0.35, 0.2), Vector3(-0.9, 0.3, 0.2)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -14.0, "neck": 10.0}},
	"ranjishigami_no_jutsu": {"base": "power", "pre": 0.35, "post": 0.6, "wind": {"R": [Vector3(-0.35, -0.85, -0.35), Vector3(0.0, -0.4, 0.9), Vector3(0.0, 0.2, 0.95)], "L": [Vector3(0.35, -0.85, -0.35), Vector3(-0.0, -0.4, 0.9), Vector3(-0.0, 0.2, 0.95)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 30.0, "neck": -25.0, "crouch": 0.5}, "rel": {"R": [Vector3(-0.1, -0.35, 0.93), Vector3(0.0, -0.3, 0.95), Vector3(0.0, 0.5, 0.85)], "L": [Vector3(0.1, -0.35, 0.93), Vector3(-0.0, -0.3, 0.95), Vector3(-0.0, 0.5, 0.85)], "fR": [0.6, 0.6, 0.6, 0.6, 0.4], "fL": [0.6, 0.6, 0.6, 0.6, 0.4], "spine": 20.0, "neck": 20.0}},
	"hari_jizo": {"base": "power", "pre": 0.2, "post": 0.5, "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 30.0, "crouch": 0.6}, "rel": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "spine": 60.0, "neck": -40.0, "crouch": 0.95}},
	"kuchiyose_gamaguchi_shibari": {"base": "summon", "pre": 0.5, "post": 0.9, "rel": {"R": [Vector3(-0.15, -0.55, 0.8), Vector3(0.0, -0.85, 0.5), Vector3(0.0, -0.4, 0.9)], "L": [Vector3(0.2, -0.4, 0.9), Vector3(-0.5, 0.75, 0.4), Vector3(-0.2, 0.95, 0.2)], "fR": [0.15, 0.15, 0.15, 0.15, 0.3], "fL": [0.0, 0.0, 1.5, 1.5, 0.9], "spine": 50.0, "neck": -25.0, "crouch": 1.0}},
	"katon_gamayu_endan": {"base": "breath", "pre": 0.5, "post": 0.8, "wind": {"R": [Vector3(-0.2, -0.4, 0.9), Vector3(0.5, 0.75, 0.4), Vector3(0.2, 0.95, 0.2)], "L": [Vector3(0.2, -0.4, 0.9), Vector3(-0.5, 0.75, 0.4), Vector3(-0.2, 0.95, 0.2)], "fR": [0.0, 0.0, 1.5, 1.5, 0.9], "fL": [0.0, 0.0, 1.5, 1.5, 0.9], "spine": -6.0}, "rel": {"R": [Vector3(-0.3, -0.5, 0.8), Vector3(0.6, 0.7, 0.35), Vector3(0.3, 0.9, 0.3)], "L": [Vector3(0.9, 0.4, 0.15), Vector3(0.9, 0.35, 0.2), Vector3(0.9, 0.3, 0.2)], "fR": [0.9, 1.4, 1.4, 1.4, 0.9], "fL": [0, 0, 0, 0, 0], "spine": 24.0, "neck": 12.0}},
	"senpo_kawazu_naki": {"base": "sense", "pre": 0.45, "post": 0.8, "wind": {"R": [Vector3(-0.25, -0.8, 0.5), Vector3(0.6, 0.2, 0.75), Vector3(0.5, 0.3, 0.8)], "L": [Vector3(0.25, -0.8, 0.5), Vector3(-0.6, 0.2, 0.75), Vector3(-0.5, 0.3, 0.8)], "fR": [1.45, 1.45, 1.45, 1.45, 0.9], "fL": [1.45, 1.45, 1.45, 1.45, 0.9], "crouch": 0.4}, "rel": {"R": [Vector3(-0.85, -0.45, 0.1), Vector3(-0.9, -0.3, 0.2), Vector3(-0.9, -0.2, 0.3)], "L": [Vector3(0.85, -0.45, 0.1), Vector3(0.9, -0.3, 0.2), Vector3(0.9, -0.2, 0.3)], "fR": [0, 0, 0, 0, 0], "fL": [0, 0, 0, 0, 0], "spine": -12.0, "neck": -24.0}},
}

const SNAKE := Color(0.42, 0.3, 0.5)
const SNAKE_BELLY := Color(0.78, 0.72, 0.55)

static var _pinst: PathJutsu = null
static var _mcache := {}


static func get_pinst() -> PathJutsu:
	if _pinst == null or not is_instance_valid(_pinst):
		_pinst = PathJutsu.new()
		_pinst.name = "PathJutsu"
		Jutsu.add_child(_pinst)
	return _pinst


static func handles_path(id: String) -> bool:
	return get_pinst().has_method("p_" + id)


static func cast_path(c: Node3D, id: String, t: Node3D) -> void:
	get_pinst().call("p_" + id, c, t)


# ================================================================== yardımcılar
func hand_pos(c: Node3D, right := true) -> Vector3:
	var m = c.get("model")
	if m and is_instance_valid(m) and m.skel:
		var bi = m.skel.find_bone("RightHand" if right else "LeftHand")
		if bi >= 0:
			return (m.skel.global_transform * m.skel.get_bone_global_pose(bi)).origin
	var side = c.face_dir().cross(Vector3.UP).normalized()
	return c.global_position + Vector3.UP * 1.2 + c.face_dir() * 0.4 + side * (0.3 if right else -0.3)


func bone_attach(c: Node3D, bone: String) -> Node3D:
	var m = c.get("model")
	if m == null or not is_instance_valid(m) or m.skel == null or m.skel.find_bone(bone) < 0:
		return null
	var ba = BoneAttachment3D.new()
	ba.bone_name = bone
	m.skel.add_child(ba)
	return ba


func cached(key: String, build: Callable) -> ArrayMesh:
	if not _mcache.has(key):
		var b: MB = build.call()
		_mcache[key] = b.build(Props.toon())
	return _mcache[key]


func mi_of(mesh: Mesh, mat: Material = null) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	if mat:
		mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func scene_add(n: Node3D, pos: Vector3) -> Node3D:
	get_tree().current_scene.add_child(n)
	n.global_position = pos
	return n


func toward(n: Node3D, dir: Vector3) -> void:
	if dir.length() > 0.01:
		n.look_at(n.global_position + dir, Vector3.UP if absf(dir.normalized().y) < 0.95 else Vector3.RIGHT)


## Yılan başı (ileri = -Z): uzun kafa, açık çene, sivri dişler, sarı gözler, çatal dil
func snake_head(col: Color, size: float) -> Node3D:
	var key = "shead_%s" % col.to_html(false)
	var mesh = cached(key, func():
		var b = MB.new()
		b.add_grad("sphere", Vector3(0, 0, 0), Vector3(0.62, 0.42, 0.95), col.lightened(0.12), col.darkened(0.25), Vector3.ZERO, 10)
		b.add_grad("sphere", Vector3(0, 0.04, -0.42), Vector3(0.48, 0.24, 0.62), col.lightened(0.08), col.darkened(0.2), Vector3(-8, 0, 0), 9)
		b.add("sphere", Vector3(0, -0.15, -0.38), Vector3(0.42, 0.12, 0.6), SNAKE_BELLY, Vector3(22, 0, 0), 8)   # alt çene (açık)
		for sx in [-1.0, 1.0]:
			b.add("sphere", Vector3(0.2 * sx, 0.16, -0.22), Vector3(0.13, 0.1, 0.16), Color(1.0, 0.85, 0.15), Vector3.ZERO, 6)
			b.add("box", Vector3(0.2 * sx, 0.165, -0.27), Vector3(0.02, 0.09, 0.03), Color(0.05, 0.03, 0.02))
			b.add("cone", Vector3(0.12 * sx, -0.04, -0.62), Vector3(0.05, 0.2, 0.05), Color(1, 1, 0.95), Vector3(180, 0, 0), 4)
			b.add("box", Vector3(0.05 * sx, -0.08, -1.0), Vector3(0.03, 0.015, 0.16), Color(0.85, 0.12, 0.2), Vector3(0, 18 * sx, 0))
		b.add("box", Vector3(0, -0.08, -0.82), Vector3(0.035, 0.015, 0.3), Color(0.85, 0.12, 0.2))
		return b)
	var root = Node3D.new()
	var mi = mi_of(mesh)
	mi.scale = Vector3.ONE * size * 1.3
	root.add_child(mi)
	return root


## Kafası ve kıvrılan gövdesiyle yılan: döndürülen baş düğümünü hareket ettir, gövde izini takip eder
func make_snake(from: Vector3, col: Color, size: float, segs := 10) -> Node3D:
	var head = Node3D.new()
	scene_add(head, from)
	head.add_child(snake_head(col, size))
	var body = VfxSerpent.new()
	body.head = head
	body.count = segs
	body.spacing = 0.42 * size
	body.radius = 0.32 * size
	body.mat = Props.toon_color(col)
	get_tree().current_scene.add_child(body)
	return head


## Başı a'dan b'ye kıvrılarak taşı (sinüs sapmalı yol)
func slither(head: Node3D, a: Vector3, b: Vector3, dur: float, wiggle := 0.8, done := Callable()) -> void:
	var d = b - a
	var side = d.cross(Vector3.UP).normalized()
	if side.length() < 0.1:
		side = Vector3.RIGHT
	every(dur, 1.0 / 40.0, func(_i, k):
		if not is_instance_valid(head):
			return
		var p = a.lerp(b, k) + side * sin(k * TAU * 1.5) * wiggle * (1.0 - k)
		var nx = a.lerp(b, minf(1.0, k + 0.04)) + side * sin((k + 0.04) * TAU * 1.5) * wiggle * (1.0 - k)
		head.global_position = p
		toward(head, nx - p), func():
		if is_instance_valid(head):
			head.global_position = b
		if done.is_valid():
			done.call())


func poison(c: Node3D, e: Node3D, id: String, mul: float, dur := 4.0) -> void:
	hit(c, e.global_position + Vector3.UP * e.height * 0.6, e.radius + 0.6, inf(c, id, mul, {"knock": 1.0, "kind": "light", "burn": dur, "hitstop": 0.03}))
	FX.burst(e.global_position + Vector3.UP * e.height * 0.6, {"amount": 8, "life": 0.5, "size": 0.5, "vmin": 1, "vmax": 3,
		"colors": [Color(0.6, 0.25, 0.75), Color(0.25, 0.6, 0.2, 0)]})


func cone_enemies(c: Node3D, d: Vector3, rng: float, deg: float) -> Array:
	var out = []
	for e in enemies_near(c, c.global_position, rng):
		var v = e.global_position - c.global_position
		v.y = 0
		if v.length() < 0.5 or rad_to_deg(v.normalized().angle_to(d)) <= deg * 0.5:
			out.append(e)
	out.sort_custom(func(a, b): return a.global_position.distance_to(c.global_position) < b.global_position.distance_to(c.global_position))
	return out


## Hedefi c'ye doğru çek (dur saniyede), önünde durur
func pull_to(c: Node3D, e: Node3D, dur: float, stop := 1.6) -> void:
	var from = e.global_position
	every(dur, 1.0 / 40.0, func(_i, k):
		if not live(e) or not is_instance_valid(c):
			return
		var to = c.global_position + (from - c.global_position).normalized() * (stop + e.radius)
		e.global_position = gp(from.lerp(to, k * k)), Callable())


func summon_circle(pos: Vector3, r: float, col: Color, dur: float) -> void:
	ground_disc(pos, r, col, dur, 2, 12)
	FX.smoke_puff(pos + Vector3.UP * 0.6, r * 0.35, 14)
	Sfx.play("poof", pos, 0.8)


# ================================================================== YILAN YOLU
## Sen'ei Jashu: iki yılan yenden fırlar, hedefi ısırıp sarar, sonra seni ona değil onu sana çeker
func p_sen_ei_jashu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	busy(c, 0.9)
	anim(c, "cross", 1.2)
	Sfx.play("whoosh", c.global_position, 0.7)
	var to = tt.global_position + Vector3.UP * tt.height * 0.55 if tt else c.global_position + Vector3.UP * 1.1 + fwd(c, t) * 16.0
	for k in 2:
		var from = hand_pos(c, k == 0)
		var head = make_snake(from, SNAKE, 0.9, 14)
		var side = fwd(c, t).cross(Vector3.UP).normalized() * (0.6 if k == 0 else -0.6)
		slither(head, from, to + side, 0.32, 1.2, func():
			if tt and live(tt):
				poison(c, tt, "sen_ei_jashu", 0.45, 4.0)
				st(tt, "bind", 2.4)
			else:
				FX.dust(gp(to), 0.8))
		after(0.32, func():
			if is_instance_valid(head) and tt and live(tt):
				every(1.6, 1.0 / 30.0, func(_i, _k):
					if is_instance_valid(head) and live(tt):
						head.global_position = tt.global_position + Vector3.UP * tt.height * 0.55 + side * 0.5, Callable()))
		fade_free(head, 2.2, 0.2)
	if tt:
		Combat.popup_text(tt.global_position + Vector3.UP * (tt.height + 0.8), "Yılanlar sardı!", Color(0.7, 0.5, 0.85))
		after(0.5, func():
			if live(tt):
				pull_to(c, tt, 0.5))


## Jagei Jubaku: arkanda dev bir yılan hayali yükselir, bakışınla dehşete düşen herkes donar
func p_jagei_jubaku(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 0.8)
	var victims = cone_enemies(c, d, 18.0, 110.0)
	# bakıştan doğan illüzyon: arkasından yerden kıvrılarak yükselen dev mor yılan, ağzını açıp kurbanların üstüne eğilir
	var side = d.cross(Vector3.UP).normalized()
	var root_p = gp(c.global_position - d * 4.0)
	var head = make_snake(root_p + Vector3.DOWN * 2.0, Color(0.5, 0.25, 0.62), 3.2, 22)
	var top = root_p + Vector3.UP * 9.0 + side * 2.0
	var strike = c.global_position + d * 6.0 + Vector3.UP * 5.0
	var path = [root_p + side * 3.0 + Vector3.UP * 2.0, root_p - side * 2.5 + Vector3.UP * 5.0, top, strike]
	var seq = head.create_tween()
	for k in path.size():
		seq.tween_property(head, "global_position", path[k], 0.16 if k < 3 else 0.22).set_trans(Tween.TRANS_SINE)
	seq.tween_callback(func():
		toward(head, d + Vector3.DOWN * 0.6)
		VFX.shockwave(strike, Color(0.75, 0.4, 1.0), 9.0, 0.35, false, d))
	seq.tween_interval(1.0)
	seq.tween_property(head, "global_position", root_p + Vector3.DOWN * 6.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	seq.tween_callback(head.queue_free)
	every(0.6, 1.0 / 30.0, func(_i, _k):
		if is_instance_valid(head):
			var nx = head.global_position + d * 0.5 + Vector3.DOWN * 0.15
			head.look_at(nx, Vector3.UP))
	FX.burst(root_p + Vector3.UP * 0.5, {"amount": 40, "life": 1.2, "tex": FX.tex_smoke, "add": false, "size": 2.0, "radius": 3.0, "vmin": 1, "vmax": 3,
		"colors": [Color(0.35, 0.15, 0.45, 0.6), Color(0.2, 0.05, 0.25, 0)]})
	if Game.world and c is Player:
		Game.world.env.flash_tint(Color(0.35, 0.1, 0.45, 0.18), 1.4)
	VFX.screen_lines(0.5, 0.8, Color(0.6, 0.3, 0.8))
	Sfx.play("genjutsu", c.global_position, 0.6)
	FX.flash_sphere(c.global_position + Vector3.UP * 1.6 + d * 0.3, Color(1.0, 0.85, 0.15), 0.6, 0.25)
	for e in victims:
		st(e, "stun", 3.5)
		st(e, "fear", 3.5)
		Combat.popup_text(e.global_position + Vector3.UP * (e.height + 0.8), "Dehşet!", Color(0.85, 0.6, 1.0))
		hit(c, e.global_position + Vector3.UP, e.radius + 0.4, inf(c, "jagei_jubaku", 0.2, {"knock": 0.0, "kind": "light"}))


## Yılan klonu: yerinde bir klon kalır, sen geri sıçrarsın; klon vurulunca yılan sürüsüne dağılıp çevreyi ısırır
func p_hebi_bunshin_no_jutsu(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var at = c.global_position
	FX.smoke_puff(at + Vector3.UP, 0.8, 10)
	decoy(c, at, 12.0, func(pos: Vector3):
		FX.burst(pos + Vector3.UP, {"amount": 20, "life": 0.5, "size": 0.6, "vmin": 2, "vmax": 6, "colors": [Color(0.6, 0.5, 0.7), Color(0.3, 0.25, 0.35, 0)]})
		var near = enemies_near(c, pos, 11.0)
		for k in 8:
			var e = near[k % near.size()] if not near.is_empty() else null
			var to = e.global_position + Vector3.UP * 0.6 if e else pos + Vector3(cos(k * 0.785), 0, sin(k * 0.785)) * 7.0
			var head = make_snake(pos + Vector3.UP * 0.6, SNAKE.lightened(0.1), 0.5, 7)
			slither(head, pos + Vector3.UP * 0.6, to, 0.35 + k * 0.03, 0.6, func():
				if e and live(e):
					poison(c, e, "hebi_bunshin_no_jutsu", 0.25, 3.0))
			fade_free(head, 0.8, 0.2))
	c.global_position = gp(at - d * 6.0)
	if c is Player:
		c.combat.invuln = 0.4
	FX.smoke_puff(c.global_position + Vector3.UP, 0.6, 8)


## Sen'ei Tajashu: iki koldan onlarca yılan yelpaze gibi açılır, menzildeki 6 düşmana kadar hepsini sarar
func p_sen_ei_tajashu(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 1.0)
	anim(c, "cross", 1.0)
	var victims = cone_enemies(c, d, 24.0, 140.0).slice(0, 6)
	Sfx.play("whoosh", c.global_position, 0.6)
	var n = 12
	for k in n:
		var right = k % 2 == 0
		var from = hand_pos(c, right)
		var e = victims[k % victims.size()] if not victims.is_empty() else null
		var ang = deg_to_rad(-60.0 + 120.0 * float(k) / (n - 1))
		var free_to = from + d.rotated(Vector3.UP, ang) * 20.0
		var to = e.global_position + Vector3.UP * e.height * 0.5 + Vector3(randf_range(-0.4, 0.4), randf_range(-0.3, 0.3), randf_range(-0.4, 0.4)) if e else free_to
		var head = make_snake(from, SNAKE.lerp(Color(0.3, 0.45, 0.25), randf() * 0.5), 0.7, 12)
		after(k * 0.03, func():
			if not is_instance_valid(head):
				return
			slither(head, from, to, 0.38, 1.6, func():
				if e and live(e):
					poison(c, e, "sen_ei_tajashu", 0.22, 4.0)
					st(e, "bind", 3.0)
				else:
					FX.dust(gp(to), 0.6)
					hit(c, to, 1.5, inf(c, "sen_ei_tajashu", 0.25, {"knock": 3.0, "kind": "light"}))))
		fade_free(head, 3.0, 0.25)
	for e in victims:
		Combat.popup_text(e.global_position + Vector3.UP * (e.height + 0.8), "Yılan ağı!", Color(0.7, 0.5, 0.85))


## Rashōmon kapısı: şeytan yüzlü dev kapı yerden fırlar (önündekileri havaya savurur), saldırıları gerçekten durdurur
func rashomon_gate(c: Node3D, pos: Vector3, d: Vector3, s: float, dur: float, id: String) -> Node3D:
	var mesh = cached("rashomon", func():
		var b = MB.new()
		var wood = Color(0.55, 0.12, 0.1)
		b.add("box", Vector3(0, 5.0, 0), Vector3(9.0, 10.0, 1.1), Color(0.32, 0.3, 0.33))    # kapı kanatları (demir)
		b.add("box", Vector3(0, 5.0, -0.1), Vector3(0.18, 10.0, 1.2), Color(0.15, 0.14, 0.16))
		for sx in [-1.0, 1.0]:
			b.add("box", Vector3(5.0 * sx, 6.0, 0), Vector3(1.1, 12.0, 1.6), wood)                 # direkler
			b.add("box", Vector3(5.0 * sx, 0.4, 0), Vector3(1.6, 0.8, 2.0), Color(0.25, 0.22, 0.2))
			for k in 4:
				b.add("sphere", Vector3(2.2 * sx, 1.6 + k * 2.3, -0.62), Vector3(0.32, 0.32, 0.25), Color(0.7, 0.6, 0.25), Vector3.ZERO, 6)   # perçinler
		b.add("box", Vector3(0, 12.3, 0), Vector3(12.5, 0.9, 2.2), wood)                        # üst kiriş
		b.add("box", Vector3(0, 13.2, 0), Vector3(14.0, 0.5, 2.8), Color(0.18, 0.15, 0.15))
		# şeytan yüzü
		b.add_grad("sphere", Vector3(0, 7.2, -0.7), Vector3(4.2, 4.0, 1.4), Color(0.75, 0.25, 0.18), Color(0.4, 0.1, 0.08), Vector3.ZERO, 12)
		for sx in [-1.0, 1.0]:
			b.add("sphere", Vector3(0.95 * sx, 7.9, -1.3), Vector3(0.75, 0.45, 0.3), Color(1.0, 0.9, 0.2), Vector3(0, 0, 15 * sx), 8)
			b.add("cone", Vector3(1.4 * sx, 9.4, -0.9), Vector3(0.45, 1.7, 0.45), Color(0.9, 0.85, 0.7), Vector3(0, 0, -25 * sx), 6)
			b.add("cone", Vector3(0.7 * sx, 6.0, -1.35), Vector3(0.2, 0.7, 0.2), Color(1, 1, 0.95), Vector3(180, 0, 0), 4)
		b.add("box", Vector3(0, 6.15, -1.3), Vector3(2.2, 0.35, 0.3), Color(0.1, 0.02, 0.02))
		return b)
	var gate = mi_of(mesh)
	gate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var root = Node3D.new()
	scene_add(root, gp(pos) - Vector3.UP * 13.0 * s)
	root.add_child(gate)
	gate.scale = Vector3.ONE * s
	toward(root, -d)
	# engel: gövde ve mermiler geçemez
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	var cs = CollisionShape3D.new()
	var bx = BoxShape3D.new()
	bx.size = Vector3(12.0, 13.0, 1.6) * s
	cs.shape = bx
	cs.position = Vector3(0, 6.5, 0) * s
	sb.add_child(cs)
	root.add_child(sb)
	var tw = root.create_tween()
	tw.tween_property(root, "global_position", gp(pos), 0.28).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	VFX.cracks(gp(pos), 8.0 * s)
	FX.dust(gp(pos), 2.0 * s)
	VFX.debris(gp(pos), Color(0.45, 0.38, 0.3), 18, 12.0, 0.6)
	shake(0.7 * s)
	Sfx.play("earth", pos, 0.6)
	for e in enemies_near(c, pos, 6.5 * s):
		hit(c, e.global_position + Vector3.UP, e.radius + 0.5, inf(c, id, 0.6, {"knock": 10.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.06}))
	# kapıya çarpan mermiler patlayıp söner
	var catch_r = 7.0 * s
	every(dur, 0.05, func(_i, _k):
		if not is_instance_valid(root):
			return
		for pr in get_tree().get_nodes_in_group("projectiles"):
			if pr is Projectile and is_instance_valid(pr) and pr.shooter != c and pr.global_position.distance_to(root.global_position + Vector3.UP * 6.0 * s) < catch_r:
				FX.hit_spark(pr.global_position, Color(1, 0.8, 0.4), 1.2)
				pr.queue_free(), func():
		if is_instance_valid(root):
			var t2 = root.create_tween()
			t2.tween_property(root, "global_position", root.global_position - Vector3.UP * 14.0 * s, 0.5).set_ease(Tween.EASE_IN)
			t2.tween_callback(root.queue_free)
			FX.smoke_puff(root.global_position + Vector3.UP * 3.0, 2.0 * s, 16))
	return root


func p_kuchiyose_rashomon(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 0.6)
	summon_circle(c.global_position + d * 5.0, 5.0, Color(0.85, 0.25, 0.2), 0.6)
	after(0.2, func(): rashomon_gate(c, c.global_position + d * 5.0, d, 1.0, 8.0, "kuchiyose_rashomon"))


func p_kuchiyose_sanju_rashomon(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 1.0)
	summon_circle(c.global_position + d * 6.0, 7.0, Color(0.85, 0.25, 0.2), 1.0)
	for k in 3:
		var pos = c.global_position + d * (5.0 + k * 3.2)
		var s = 1.0 + k * 0.25
		after(0.15 + k * 0.28, func(): rashomon_gate(c, pos, d, s, 10.0, "kuchiyose_sanju_rashomon"))
	after(1.0, func(): VFX.slowmo(0.5, 0.4))


## Kusanagi: ağızdan çıkan yılan kılıcı dişlerinde tutar, kılıç 25 m uzayıp hattı deler; sonra 15 sn elinde kalır
func kusanagi_blade(len_: float) -> MeshInstance3D:
	var mesh = cached("kusanagi", func():
		var b = MB.new()
		b.add_grad("box", Vector3(0, 0, -0.5), Vector3(0.12, 0.025, 1.0), Color(1.0, 1.0, 1.0), Color(0.78, 0.85, 0.95))
		b.add("box", Vector3(0, 0.0, -0.5), Vector3(0.04, 0.03, 1.0), Color(0.6, 0.7, 0.9))   # oluk
		b.add("box", Vector3(0, 0, 0.04), Vector3(0.2, 0.07, 0.06), Color(0.7, 0.6, 0.3))
		b.add("cyl", Vector3(0, 0, 0.16), Vector3(0.05, 0.22, 0.05), Color(0.2, 0.12, 0.25), Vector3(90, 0, 0), 6)
		return b)
	var mi = mi_of(mesh)
	mi.scale = Vector3(1, 1, len_)
	return mi


func p_kusanagi_kuchi(c: Node3D, t: Node3D) -> void:
	var d = Jutsu._aim(c, t)
	busy(c, 1.1)
	if c is Player and t:
		c.combat.face_to(t)
	var mouth = Jutsu._mouth(c)
	var head = make_snake(mouth, Color(0.55, 0.45, 0.6), 0.45, 6)
	slither(head, mouth, mouth + d * 1.6, 0.25, 0.1)
	var blade = kusanagi_blade(1.0)
	head.add_child(blade)
	blade.position = Vector3(0, -0.05, -0.35)
	Sfx.play("clink", mouth, 0.7)
	var hits = []
	after(0.28, func():
		if not is_instance_valid(blade):
			return
		VFX.trail(blade, 0.5, Color(1, 1, 1), Color(0.75, 0.85, 1.0), Color(0.5, 0.6, 1.0, 0.0), 12, 0.5)
		VFX.star(mouth + d * 0.6, Color(0.85, 0.9, 1.0), 2.5, 0.15)
		var tw = blade.create_tween()
		tw.tween_property(blade, "scale", Vector3(1.6, 1.6, 25.0), 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.25)
		tw.tween_property(blade, "scale", Vector3(1, 1, 0.6), 0.2)
		Sfx.play("whoosh", mouth, 1.4)
		after(0.12, func():
			for k in 17:
				var p = mouth + d * (1.5 + k * 1.5)
				for h in hit(c, p, 0.9, inf(c, "kusanagi_kuchi", 1.6, {"knock": 6.0, "kind": "heavy", "pierce_guard": true, "burn": 2.0, "hitstop": 0.08}), hits):
					hits.append(h)
					FX.hit_spark(h.global_position + Vector3.UP, Color(0.85, 0.9, 1.0), 1.4)
			FX.speed_lines(mouth + d * 12.0, d)
			for k in 5:
				VFX.shockwave(mouth + d * (4.0 + k * 5.0), Color(0.8, 0.9, 1.0), 2.5, 0.25, false, d)
			shake(0.4)))
	fade_free(head, 1.0, 0.2)
	# kılıç 15 sn sağ elde: vuruşlar uzar ve güçlenir
	if c is Player:
		Buffs.add("kusanagi", 15.0, {"melee": 1.35, "reach": 1.6})
		var ba = bone_attach(c, "RightHand")
		if ba:
			var hb = kusanagi_blade(1.15)
			ba.add_child(hb)
			hb.position = Vector3(0, 0.05, 0)
			hb.rotation_degrees = Vector3(-90, 0, 0)
			after(15.0, func():
				if is_instance_valid(ba):
					ba.queue_free())


## Gogyō Fūin: beş parmak ucunda beş element yanar; karnına bastırılan mühür chakrayı 12 sn kilitler
func p_gogyo_fuin(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 9.0)
	if tt == null:
		Hud.msg("Gogyō Fūin: hedef en fazla 9 metrede olmalı", Color(0.85, 0.75, 1.0))
		return
	var cols = [Color(1, 0.4, 0.1), Color(0.3, 0.6, 1.0), Color(0.6, 1.0, 0.7), Color(0.75, 0.55, 0.3), Color(1.0, 1.0, 0.4)]
	var hp_ = hand_pos(c, true)
	var dots = []
	for k in 5:
		var s = MeshInstance3D.new()
		s.mesh = VFX._sphere(0.09, 10, 6)
		s.material_override = glow(cols[k])
		scene_add(s, hp_ + Vector3(cos(k * 1.256) * 0.18, sin(k * 1.256) * 0.18 + 0.05, 0))
		dots.append(s)
	busy(c, 0.8)
	after(0.35, func():
		if not live(tt):
			return
		c.global_position = gp(tt.global_position - (tt.global_position - c.global_position).normalized() * (tt.radius + 0.9))
		if c is Player:
			c.combat.face_to(tt)
		anim(c, "cross", 2.0)
		var belly = tt.global_position + Vector3.UP * tt.height * 0.5
		for k in 5:
			var s: MeshInstance3D = dots[k]
			if is_instance_valid(s):
				var tw = s.create_tween()
				tw.tween_property(s, "global_position", belly + Vector3(cos(k * 1.256) * 0.3, sin(k * 1.256) * 0.3, 0), 0.12)
				tw.tween_callback(s.queue_free)
		after(0.12, func():
			if not live(tt):
				return
			hit(c, belly, tt.radius + 0.5, inf(c, "gogyo_fuin", 0.9, {"knock": 7.0, "kind": "heavy", "hitstop": 0.12}))
			seal_points(tt, 12.0, Color(0.85, 0.55, 1.0))
			var ring = ground_disc(belly - Vector3.UP * tt.height * 0.5, 2.2, Color(0.8, 0.5, 1.0), 1.2, 2, 5)
			ring.global_position = belly
			VFX.shockwave(belly, Color(0.85, 0.6, 1.0), 4.0, 0.3, false, (belly - c.global_position).normalized())
			Combat.popup_text(belly + Vector3.UP * 1.2, "Beş Element Mühürü: chakra kilitlendi!", Color(0.85, 0.65, 1.0))
			Sfx.play("seal", belly, 0.8)))


## Sen'ei Ranjashu: koni boyunca üç dalga halinde yerden vahşi yılanlar fışkırıp dalar
func p_sen_ei_ranjashu(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 0.7)
	VFX.cracks(c.global_position + d * 2.0, 4.0)
	var hits = {}
	for wave in 3:
		for k in 7:
			var ang = deg_to_rad(-26.0 + 52.0 * float(k) / 6.0 + randf_range(-4, 4))
			var dist = 6.0 + wave * 7.0 + randf_range(-1.5, 1.5)
			var g = gp(c.global_position + d.rotated(Vector3.UP, ang) * dist)
			after(0.1 + wave * 0.22 + k * 0.02, func():
				var head = make_snake(g - Vector3.UP * 1.0, SNAKE.lerp(Color(0.25, 0.35, 0.2), randf()), 0.75, 9)
				var top = g + Vector3.UP * randf_range(3.5, 5.5) + d * 1.5
				var land = g + d * 4.5 - Vector3.UP * 1.2
				FX.dust(g, 0.6)
				slither(head, g - Vector3.UP * 1.0, top, 0.22, 0.3, func():
					slither(head, top, land, 0.3, 0.3))
				for e in enemies_near(c, g, 2.6):
					if not hits.has(e):
						hits[e] = true
						poison(c, e, "sen_ei_ranjashu", 0.55, 4.0)
						st(e, "slow", 4.0)
						hit(c, e.global_position + Vector3.UP, e.radius + 0.4, inf(c, "sen_ei_ranjashu", 0.25, {"knock": 3.0, "launch": 7.0, "kind": "heavy"}))
				fade_free(head, 0.9, 0.2))
	shake(0.4)
	Sfx.play("earth", c.global_position, 0.8)


## Lanetli mühür desenleri: boyun mühüründen bedene yayılan kara alev dilleri
func juin_marks(c: Node3D, col: Color, dur: float, spread: float) -> Array:
	var out = []
	var mat = flat_mat(col)
	for bone in ["Neck", "UpperChest", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "Head", "LeftUpperLeg", "RightUpperLeg"]:
		var ba = bone_attach(c, bone)
		if ba == null:
			continue
		var b = MB.new()
		var n = 3 if bone != "Head" else 2
		for k in n:
			var a = k * TAU / n + randf() * 0.6
			var r = 0.085 if bone in ["Neck", "Head"] else (0.13 if bone == "UpperChest" else 0.065)
			b.add("cone", Vector3(cos(a) * r, 0.05 + k * 0.04, sin(a) * r), Vector3(0.05, 0.16, 0.012), Color.WHITE, Vector3(0, rad_to_deg(-a), randf_range(-35, 35)), 4)
		var mi = mesh_of(b, mat)
		ba.add_child(mi)
		mi.scale = Vector3.ONE * 0.05
		var tw = mi.create_tween()
		tw.tween_interval(randf() * 0.25 + (0.0 if bone == "Neck" else 0.25))
		tw.tween_property(mi, "scale", Vector3.ONE * spread, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		out.append(ba)
	after(dur, func():
		for ba in out:
			if is_instance_valid(ba):
				ba.queue_free())
	return out


## Ten no Juin — 1. aşama: kara alev desenleri, güç ve hız; can yavaşça erir (canın %15'in altına inince söner)
func p_ten_no_juin(c: Node3D, _t: Node3D) -> void:
	var dur = 22.0
	juin_marks(c, Color(0.04, 0.02, 0.05), dur, 1.0)
	var a = FX.aura(c, Color(0.35, 0.08, 0.45), 1.3, Vector3(0, 0.9, 0), 0.0)
	Sfx.play("genjutsu", c.global_position, 0.5)
	VFX.shockwave(c.global_position + Vector3.UP, Color(0.4, 0.1, 0.5), 6.0, 0.35, true)
	if c is Player:
		Buffs.add("juin1", dur, {"melee": 1.3, "jutsu": 1.25, "speed": 1.15, "_desc": "her sn canın %1'i erir"})
		Hud.msg("Lanetli mühür uyandı: güç akıyor... ama bedel ağır.", Color(0.8, 0.55, 0.95))
	every(dur, 1.0, func(_i, _k):
		if is_instance_valid(c) and c.hp > c.max_hp * 0.15 and (not c is Player or Buffs.has("juin1")):
			c.hp -= c.max_hp * 0.01
		elif c is Player:
			Buffs.remove("juin1"), func():
		if is_instance_valid(a):
			a.emitting = false)


## 2. aşama: ten grileşir, sırttan el biçimli kanatlar açılır, uçabilirsin; güç patlar, can hızla erir
func hand_wing(right: bool) -> MeshInstance3D:
	var mesh = cached("handwing2", func():
		var b = MB.new()
		var sk = Color(0.52, 0.48, 0.58)
		b.add_grad("cyl", Vector3(0, 0.45, 0), Vector3(0.2, 0.9, 0.2), sk.lightened(0.1), sk.darkened(0.25), Vector3.ZERO, 8)   # bilek
		b.add_grad("sphere", Vector3(0, 1.15, 0), Vector3(0.78, 0.7, 0.2), sk.lightened(0.05), sk.darkened(0.3), Vector3.ZERO, 12)   # avuç
		for f in 5:
			var a = deg_to_rad(-62.0 + f * 31.0)
			var L = [0.95, 1.5, 1.7, 1.5, 1.1][f]
			var base = Vector3(sin(a) * 0.3, 1.3 + cos(a) * 0.3, 0)
			var dir = Vector3(sin(a), cos(a), 0)
			b.add_grad("cyl", base + dir * L * 0.25, Vector3(0.13, L * 0.5, 0.11), sk.lightened(0.05), sk.darkened(0.25), Vector3(0, 0, -rad_to_deg(a)), 6)
			b.add_grad("cone", base + dir * L * 0.72, Vector3(0.12, L * 0.48, 0.1), sk, sk.darkened(0.35), Vector3(0, 0, -rad_to_deg(a)), 6)
			b.add("cone", base + dir * (L * 0.98), Vector3(0.06, 0.16, 0.05), Color(0.12, 0.08, 0.14), Vector3(0, 0, -rad_to_deg(a)), 4)   # tırnak
		return b)
	var mi = mi_of(mesh)
	mi.scale = Vector3(-1 if not right else 1, 1, 1)
	return mi


const JUIN_FORMS := {
	"kanat": {"name": "Kanatlı Form", "skin": Color(0.56, 0.52, 0.6), "desc": "Sırttan el kanatlar: uçabilirsin (Space/Ctrl)",
		"mods": {"melee": 1.5, "jutsu": 1.4, "speed": 1.3}},
	"boynuz": {"name": "Boynuzlu Form", "skin": Color(0.8, 0.46, 0.38), "desc": "Alnından boynuzlar: jutsu ve genjutsu çok güçlü",
		"mods": {"jutsu": 1.8, "melee": 1.25, "speed": 1.15}},
	"kaya": {"name": "Kaya Deri", "skin": Color(0.86, 0.56, 0.3), "desc": "Sırtta kaya yumruları: darbelere dayanıklı, yumrukların ağır",
		"mods": {"melee": 1.9, "armor": 0.55, "speed": 1.05}},
	"orumcek": {"name": "Örümcek Formu", "skin": Color(0.46, 0.33, 0.26), "desc": "Sırttan iki çift ek kol: çok hızlı ve uzun erimli",
		"mods": {"melee": 1.6, "speed": 1.45, "reach": 1.4}},
}


## Lanetli mühür II beden parçaları: kemiğe (sırt/baş) bağlı, büyüyerek çıkar. Döner: silinecek düğümler
func juin_parts(c: Node3D, form: String) -> Array:
	var m = c.get("model")
	var out = []
	if m == null or m.skel == null:
		return out
	var sk: Skeleton3D = m.skel
	var chest_b = "UpperChest" if sk.find_bone("UpperChest") >= 0 else "Chest"
	var p_ch: Vector3 = m._grest(sk.find_bone(chest_b)).origin
	var skin_c: Color = JUIN_FORMS[form]["skin"]
	var dark = skin_c.darkened(0.35)
	var grow = func(node: Node3D, sc: Vector3):
		node.scale = sc * 0.05
		node.create_tween().tween_property(node, "scale", sc, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	match form:
		"kanat":
			for right in [true, false]:
				var sx = -1.0 if right else 1.0   # model uzayı: +X karakterin solu, -Z sırt
				var ba = m._attach(chest_b, Transform3D(Basis.IDENTITY, p_ch + Vector3(sx * 0.12, 0.08, -0.14)))
				var w = hand_wing(right)
				ba.get_child(0).add_child(w)
				w.rotation_degrees = Vector3(18, 180, 62 * sx)   # dışa-yukarı açılır, avuç geriye
				grow.call(w, Vector3(-0.62 if not right else 0.62, 0.62, 0.62))   # animedeki gibi: sırttan çıkan, gövdeyi aşmayan el kanatlar
				out.append(ba)
		"boynuz":
			var hb = sk.find_bone("Head")
			var p_h: Vector3 = m._grest(hb).origin
			var top = maxf(float(m.head_ab.end.y) - 0.03, p_h.y + 0.15) if m.head_ab.size != Vector3.ZERO else p_h.y + 0.2
			var mb = MB.new()
			for sx in [-1.0, 1.0]:
				for k in 2:
					var b0 = Vector3(sx * (0.045 + k * 0.05), top - 0.04 * k, 0.05 - k * 0.04)
					Loft.tube(mb, [b0, b0 + Vector3(sx * 0.03, 0.09, -0.02), b0 + Vector3(sx * 0.07, 0.16 - k * 0.04, -0.07)], [0.028 - k * 0.006, 0.018, 0.004], [dark, skin_c, Color(0.15, 0.1, 0.1)], 8, 3, true, false)
			var ba = m._attach("Head", Transform3D.IDENTITY)
			var mi = mesh_of(mb)
			ba.get_child(0).add_child(mi)
			out.append(ba)
		"kaya":
			var mb = MB.new()
			var rng = RandomNumberGenerator.new()
			rng.seed = 77
			for k in 9:
				var a = rng.randf_range(-1.2, 1.2)
				var q = p_ch + Vector3(sin(a) * 0.14, rng.randf_range(-0.18, 0.12), -0.12 - cos(a) * 0.04)
				mb.add("boulder", q, Vector3.ONE * rng.randf_range(0.07, 0.12), skin_c.darkened(rng.randf_range(0.1, 0.3)), Vector3(0, rng.randf() * 360, 0), k)
			for sx in [-1.0, 1.0]:   # omuz yumruları
				mb.add("boulder", p_ch + Vector3(sx * 0.17, 0.12, -0.02), Vector3(0.12, 0.1, 0.12), dark, Vector3.ZERO, 3)
			var ba = m._attach(chest_b, Transform3D.IDENTITY)
			var holder = Node3D.new()
			holder.position = p_ch
			ba.get_child(0).add_child(holder)
			var mi = mesh_of(mb)
			mi.position = -p_ch
			holder.add_child(mi)
			grow.call(holder, Vector3.ONE)
			out.append(ba)
		"orumcek":
			var mb = MB.new()
			for sx in [-1.0, 1.0]:
				for k in 2:
					var s0 = p_ch + Vector3(sx * 0.1, 0.02 - k * 0.12, -0.12)
					var s1 = s0 + Vector3(sx * 0.3, 0.12 - k * 0.15, -0.12)
					var s2 = s1 + Vector3(sx * 0.18, -0.25, 0.22)
					Loft.tube(mb, [s0, s1, s2], [0.045, 0.04, 0.035], skin_c, 10, 3, true, false)
					mb.add("sphere", s2 + Vector3(0, -0.03, 0.03), Vector3(0.08, 0.06, 0.1), skin_c.darkened(0.1), Vector3.ZERO, 8)
					mb.add("sphere", s1, Vector3(0.06, 0.06, 0.06), dark, Vector3.ZERO, 8)
			var ba = m._attach(chest_b, Transform3D.IDENTITY)
			var holder = Node3D.new()
			holder.position = p_ch
			ba.get_child(0).add_child(holder)
			var mi = mesh_of(mb)
			mi.position = -p_ch
			holder.add_child(mi)
			grow.call(holder, Vector3.ONE)
			out.append(ba)
	return out


func p_juin_ni_no_dankai(c: Node3D, _t: Node3D) -> void:
	var dur = 18.0
	juin_marks(c, Color(0.02, 0.0, 0.03), dur, 1.6)
	var a = FX.aura(c, Color(0.25, 0.05, 0.35), 1.8, Vector3(0, 0.9, 0), 0.0)
	VFX.slowmo(0.4, 0.5)
	shake(0.8)
	Sfx.play("roar", c.global_position, 0.8)
	VFX.shockwave(c.global_position + Vector3.UP, Color(0.3, 0.05, 0.4), 12.0, 0.45, true)
	# form: her kullanıcının mührü farklı uyanır (Sasuke tipi kanat, Tayuya tipi boynuz, Jirōbō tipi kaya deri, Kidōmaru tipi ek kollar)
	var form = "kanat"
	if c is Player:
		if not Game.profile.has("juin_form"):
			Game.profile["juin_form"] = ["kanat", "boynuz", "kaya", "orumcek"].pick_random()
		form = String(Game.profile["juin_form"])
	else:
		form = ["kanat", "boynuz", "kaya", "orumcek"][abs(c.get_instance_id()) % 4]
	var F = JUIN_FORMS[form]
	# ten rengi değişir (deri malzemeleri)
	var skin_mats = []
	var m = c.get("model")
	if m and is_instance_valid(m):
		var ratio: Color = m._skin_ratio()
		for sm in m.materials:
			if sm is ShaderMaterial and sm.get_shader_parameter("tint") == ratio:
				skin_mats.append(sm)
				sm.set_shader_parameter("tint", F["skin"])
	# beden parçaları: kemiğe bağlı (gövdeyle hareket eder)
	var parts = juin_parts(c, form) if m and is_instance_valid(m) else []
	var wings = parts
	if c is Player:
		var mods: Dictionary = (F["mods"] as Dictionary).duplicate()
		mods["_name"] = "Lanetli Mühür II — %s" % F["name"]
		mods["_desc"] = F["desc"]
		Buffs.add("juin2", dur, mods)
		Buffs.remove("juin1")
		if form == "kanat":
			c.start_flight("juin", {"drain": 0.0, "speed": 18.0, "dur": dur})
		Hud.msg("İkinci aşama — %s! %s. Canın hızla eriyor!" % [F["name"], F["desc"]], Color(0.85, 0.55, 1.0))
	every(dur, 1.0, func(_i, _k):
		if is_instance_valid(c) and c.hp > c.max_hp * 0.1:
			c.hp -= c.max_hp * 0.03, func():
		if is_instance_valid(a):
			a.emitting = false
		for sm in skin_mats:
			if is_instance_valid(m):
				sm.set_shader_parameter("tint", m._skin_ratio())
		for w in wings:
			if is_instance_valid(w):
				w.queue_free()
		if c is Player and is_instance_valid(c) and c.flight_source() == "juin":
			c.stop_flight())


## Mandara no Jin: ağızdan on binlerce yılan seli — 70° yelpazede 38 m boyunca her şeyi ısırıp sürükler
func p_mandara_no_jin(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	busy(c, 1.6)
	var mouth = Jutsu._mouth(c)
	VFX.slowmo(0.6, 0.35)
	shake(0.6)
	Sfx.play("roar", mouth, 0.6)
	FX.burst(mouth + d * 0.6, {"amount": 30, "life": 0.6, "size": 0.9, "vmin": 4, "vmax": 12, "colors": [Color(0.45, 0.35, 0.5), Color(0.2, 0.18, 0.22, 0)]})
	var hits = {}
	for k in 16:
		var ang = deg_to_rad(-35.0 + 70.0 * float(k) / 15.0)
		var dd = d.rotated(Vector3.UP, ang)
		var start = mouth + dd * 0.8
		var g0 = gp(c.global_position + dd * 3.0) + Vector3.UP * 0.5
		var end_ = gp(c.global_position + dd * randf_range(30.0, 38.0)) + Vector3.UP * 0.5
		after(k * 0.04, func():
			var head = make_snake(start, SNAKE.lerp(Color(0.3, 0.3, 0.25), randf() * 0.6), 0.8, 12)
			slither(head, start, g0, 0.12, 0.2, func():
				slither(head, g0, end_, 1.4, 2.2))
			every(1.6, 0.1, func(_i, _k):
				if not is_instance_valid(head):
					return
				for e in enemies_near(c, head.global_position, 2.4):
					if not hits.has(e):
						hits[e] = true
						poison(c, e, "mandara_no_jin", 0.7, 5.0)
						st(e, "slow", 5.0)
					if live(e):
						e.global_position = gp(e.global_position + dd * 0.6), Callable())
			fade_free(head, 1.8, 0.3))
	# zeminde kıvranan yılan halısı izi
	for k in 10:
		after(0.2 + k * 0.12, func(): FX.dust(gp(c.global_position + d * (4.0 + k * 3.2)), 1.6))


## Kabuk değiştirme: eski beden griye dönüp yarılır, ağzından yepyeni bedenle çıkarsın (%45 can, durumlar temizlenir)
func p_orochimaru_ryu_no_kawarimi_no_jutsu(c: Node3D, _t: Node3D) -> void:
	var m = c.get("model")
	if m == null or not is_instance_valid(m):
		return
	var husk = CharacterModel.new()
	get_tree().current_scene.add_child(husk)
	husk.setup(m.look.duplicate())
	husk.global_transform = m.global_transform
	husk.play("hit", 0.0, 0.2)
	for sm in husk.materials:
		if sm is ShaderMaterial:
			sm.set_shader_parameter("tint", Color(0.62, 0.6, 0.58))
	var tw = husk.create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(husk, "scale", Vector3(1.15, 0.25, 1.15), 0.5).set_ease(Tween.EASE_IN)
	tw.tween_interval(3.0)
	tw.tween_property(husk, "scale", Vector3(1.2, 0.02, 1.2), 0.6)
	tw.tween_callback(husk.queue_free)
	FX.burst(c.global_position + Vector3.UP, {"amount": 26, "life": 0.7, "size": 0.6, "vmin": 2, "vmax": 7, "colors": [Color(0.85, 0.85, 0.75), Color(0.6, 0.7, 0.5, 0)]})
	VFX.splash(c.global_position, 2.0)
	Sfx.play("water", c.global_position, 0.6)
	var d = c.face_dir()
	c.global_position = gp(c.global_position + d * 2.0)
	m.scale = Vector3.ONE * 0.3 * m.age_scale
	var t2 = m.create_tween()
	t2.tween_property(m, "scale", Vector3.ONE * m.age_scale, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	heal(c, c.max_hp * 0.45)
	for s in ["burn", "bind", "slow", "stun", "sealed", "poison", "marked", "fear", "frozen", "chilled", "shocked", "mud"]:
		if c.get("statuses") is Dictionary:
			c.statuses.erase(s)
	if c is Player:
		c.combat.invuln = 1.2
	Combat.popup_text(c.global_position + Vector3.UP * 2.4, "Kabuk değiştirdi!", Color(0.85, 0.95, 0.8))


## Beyaz Yılan Bilge Modu: pullar bedeni sarar, yaralar kapanır; her 1.4 sn yakındaki düşmana beyaz yılan saldırır, düşmanlar sezilir
func p_hakuja_sennin_modo(c: Node3D, _t: Node3D) -> void:
	var dur = 30.0
	var a = FX.aura(c, Color(0.92, 0.9, 1.0), 1.5, Vector3(0, 0.9, 0), 0.0)
	juin_marks(c, Color(0.95, 0.93, 1.0), dur, 0.8)   # beyaz pullar
	VFX.shockwave(c.global_position + Vector3.UP * 0.2, Color(0.95, 0.95, 1.0), 14.0, 0.5, true)
	Sfx.play("heal", c.global_position, 0.7)
	if c is Player:
		Buffs.add("hakuja", dur, {"melee": 1.25, "armor": 0.85, "jutsu": 1.15})
	for e in enemies_near(c, c.global_position, 34.0):
		st(e, "marked", dur)
		Combat.popup_text(e.global_position + Vector3.UP * (e.height + 0.8), "Sezildi", Color(0.9, 0.9, 1.0))
	every(dur, 1.4, func(i, _k):
		if not is_instance_valid(c) or (c is Player and not Buffs.has("hakuja")):
			return
		if i % 2 == 0:
			heal(c, c.max_hp * 0.03)
		var near = enemies_near(c, c.global_position, 13.0)
		if near.is_empty():
			return
		var e = near[i % near.size()]
		var from = c.global_position + Vector3.UP * 1.1
		var head = make_snake(from, Color(0.95, 0.94, 0.98), 0.6, 9)
		slither(head, from, e.global_position + Vector3.UP * e.height * 0.6, 0.25, 0.7, func():
			if live(e):
				poison(c, e, "hakuja_sennin_modo", 0.35, 3.0))
		fade_free(head, 0.6, 0.2), func():
		if is_instance_valid(a):
			a.emitting = false)


## Yamata no Jutsu: sekiz başlı dev yılana dönüşürsün; başlar ayrı ayrı 40 m'ye kadar dalar, sen gövdeyle yürürsün
func p_yamata_no_jutsu(c: Node3D, _t: Node3D) -> void:
	var dur = 16.0
	var m = c.get("model")
	VFX.slowmo(0.4, 0.6)
	shake(1.2)
	Sfx.play("roar", c.global_position, 0.5)
	FX.smoke_puff(c.global_position + Vector3.UP * 2.0, 4.0, 24)
	if m:
		m.visible = false
	if c is Player:
		Buffs.add("yamata", dur, {"armor": 0.45, "speed": 0.85})
		# dev beden: kamera geri çekilip yükselir (kamera gövdenin içinde kalıyordu)
		var cd0 = c.cam_dist
		c.cam_dist = 26.0
		after(dur, func(): if is_instance_valid(c): c.cam_dist = cd0)
	var col = Color(0.36, 0.28, 0.42)
	var mound = MB.new()
	mound.add_grad("sphere", Vector3(0, 1.5, 0), Vector3(9.0, 5.0, 10.0), col.lightened(0.1), col.darkened(0.3), Vector3.ZERO, 14)
	for k in 6:
		mound.add_grad("sphere", Vector3(cos(k) * 4.0, 0.8, sin(k) * 4.5), Vector3(4.0, 2.4, 5.0), col, col.darkened(0.35), Vector3(0, k * 50, 0), 10)
	var body = place(mound, c.global_position)
	var heads = []
	for k in 8:
		var ang = TAU * k / 8.0
		var h = make_snake(c.global_position + Vector3.UP * 3.0, col.lerp(Color(0.5, 0.4, 0.3), k % 3 * 0.2), 2.6, 18)
		heads.append({"n": h, "ang": ang, "cd": 0.6 + k * 0.22, "busy": 0.0, "y": randf_range(9.0, 14.0)})
	var tick = func(_i, _k):
		if not is_instance_valid(c):
			return
		if is_instance_valid(body):
			body.global_position = c.global_position
		for hd in heads:
			var h: Node3D = hd["n"]
			if not is_instance_valid(h):
				continue
			hd["cd"] -= 1.0 / 30.0
			if hd["busy"] > 0.0:
				hd["busy"] -= 1.0 / 30.0
				continue
			var tt = Time.get_ticks_msec() * 0.001
			var rest = c.global_position + Vector3(cos(hd["ang"] + sin(tt * 0.7) * 0.2) * 6.0, hd["y"] + sin(tt * 1.3 + hd["ang"]) * 0.8, sin(hd["ang"] + sin(tt * 0.7) * 0.2) * 6.0)
			h.global_position = h.global_position.lerp(rest, 0.12)
			toward(h, (rest - c.global_position).normalized() + Vector3.DOWN * 0.3)
			if hd["cd"] <= 0.0:
				var near = enemies_near(c, c.global_position, 40.0)
				if not near.is_empty():
					var e = near[randi() % near.size()]
					hd["cd"] = randf_range(1.4, 2.2)
					hd["busy"] = 0.75
					var from = h.global_position
					var to = e.global_position + Vector3.UP * e.height * 0.5
					slither(h, from, to, 0.28, 1.0, func():
						if live(e):
							hit(c, e.global_position + Vector3.UP, e.radius + 2.2, inf(c, "yamata_no_jutsu", 1.1, {"knock": 14.0, "launch": 7.0, "kind": "heavy", "burn": 3.0, "hitstop": 0.08}))
							FX.dust(gp(e.global_position), 1.8)
							shake(0.35))
	every(dur, 1.0 / 30.0, tick, func():
		for hd in heads:
			if is_instance_valid(hd["n"]):
				hd["n"].queue_free()
		if is_instance_valid(body):
			fade_free(body, 0.0, 0.5)
		if m and is_instance_valid(m):
			m.visible = true
		if is_instance_valid(c):
			FX.smoke_puff(c.global_position + Vector3.UP * 2.0, 3.0, 18))


## Edo Tensei: topraktan iki tabut yükselir, kapakları düşer; çatlak tenli diriltilmiş ninjalar 30 sn senin için savaşır
func p_kuchiyose_edo_tensei(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var side = d.cross(Vector3.UP).normalized()
	busy(c, 1.2)
	summon_circle(c.global_position + d * 4.0, 5.0, Color(0.5, 0.35, 0.25), 1.2)
	VFX.screen_lines(0.6, 0.6, Color(0.4, 0.3, 0.25))
	Sfx.play("earth", c.global_position, 0.5)
	var cof = cached("coffin", func():
		var b = MB.new()
		b.add_grad("box", Vector3(0, 1.3, 0), Vector3(1.3, 2.6, 0.8), Color(0.5, 0.4, 0.32), Color(0.32, 0.25, 0.2))
		b.add("box", Vector3(0, 2.4, -0.42), Vector3(1.0, 0.5, 0.05), Color(0.9, 0.86, 0.7))
		return b)
	for k in 2:
		var pos = gp(c.global_position + d * 4.0 + side * (k * 2.6 - 1.3))
		var coffin = mi_of(cof)
		coffin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		scene_add(coffin, pos - Vector3.UP * 2.8)
		toward(coffin, -d)
		var tw = coffin.create_tween()
		tw.tween_property(coffin, "global_position", pos, 0.6).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.5)
		tw.tween_callback(func():
			FX.smoke_puff(pos + Vector3.UP * 1.3, 0.9, 10)
			Sfx.play("poof", pos, 0.9)
			var w = EdoWarrior.new()
			w.team = c.team
			w.owner_f = c
			w.look = EdoWarrior.edo_look(k)
			w.power = (Stats.jutsu_mult(Game.profile) if c is Player else float(c.get("power") if c.get("power") != null else 1.0)) * 1.6
			get_tree().current_scene.add_child(w)
			w.global_position = pos + d * 1.2)
		tw.tween_interval(28.0)
		tw.tween_property(coffin, "global_position", pos - Vector3.UP * 3.0, 0.6)
		tw.tween_callback(coffin.queue_free)


## Sōjasōsai: iki dev yılan seni ve hedefi sarar; canının yarısı karşılığında hedefe ölümcül darbe
func p_sojasosai_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	if tt == null:
		Hud.msg("Sōjasōsai: hedef en fazla 14 metrede olmalı", Color(0.85, 0.7, 1.0))
		return
	busy(c, 1.6)
	if c is Player:
		c.combat.invuln = 1.6
	st(tt, "bind", 1.6)
	VFX.slowmo(0.35, 0.8)
	Sfx.play("genjutsu", c.global_position, 0.4)
	var cols = [Color(0.95, 0.95, 0.98), Color(0.1, 0.08, 0.12)]
	var who = [c, tt]
	for k in 2:
		var e: Node3D = who[k]
		var head = make_snake(e.global_position + Vector3(2.5, 0.2, 0), cols[k], 1.4, 16)
		var center = e.global_position
		every(1.4, 1.0 / 40.0, func(i, kk):
			if not is_instance_valid(head) or not is_instance_valid(e):
				return
			var a = kk * TAU * 2.5 + k * PI
			head.global_position = center + Vector3(cos(a) * 1.6, 0.3 + kk * 3.0, sin(a) * 1.6)
			toward(head, Vector3(-sin(a), 0.4, cos(a))), Callable())
		fade_free(head, 1.6, 0.2)
	ground_disc(tt.global_position, 4.0, Color(0.55, 0.25, 0.7), 1.5, 3, 6)
	after(1.4, func():
		if not live(tt):
			return
		var p = tt.global_position + Vector3.UP
		FX.flash_sphere(p, Color(0.8, 0.6, 1.0), 6.0, 0.4)
		VFX.shockwave(p, Color(0.5, 0.2, 0.7), 14.0, 0.5, false)
		shake(1.0)
		hit(c, p, tt.radius + 1.0, inf(c, "sojasosai_no_jutsu", 6.0, {"knock": 4.0, "kind": "heavy", "pierce_guard": true, "hitstop": 0.2}))
		if is_instance_valid(c):
			c.hp = maxf(1.0, c.hp * 0.5)
			Combat.popup_text(c.global_position + Vector3.UP * 2.4, "Bedel: canının yarısı", Color(0.85, 0.55, 0.9)))


# ================================================================== SİLAH USTASI YOLU
const WEAPON_KINDS := ["kunai", "fuma", "kama", "katana", "sai", "ono", "kusari", "chakram", "yari", "tonfa", "senbon", "shuriken"]


## Silah meshleri (uç = -Z): her biri ayrı biçim
func weapon_mesh(kind: String) -> ArrayMesh:
	return cached("wpn_" + kind, func():
		var b = MB.new()
		var steel = Color(0.78, 0.8, 0.86)
		var dark = Color(0.22, 0.2, 0.22)
		var wrap = Color(0.55, 0.18, 0.15)
		match kind:
			"kunai":
				b.add("box", Vector3(0, 0, -0.28), Vector3(0.11, 0.025, 0.5), steel)
				b.add("cyl", Vector3(0, 0, 0.12), Vector3(0.05, 0.3, 0.05), wrap, Vector3(90, 0, 0), 6)
				b.add("torus", Vector3(0, 0, 0.32), Vector3(0.12, 0.12, 0.12), dark, Vector3(90, 0, 0), 8)
			"shuriken":
				for k in 4:
					b.add("box", Vector3.ZERO, Vector3(0.6, 0.02, 0.1), steel, Vector3(0, k * 45, 0))
			"fuma":
				for k in 4:
					b.add("box", Vector3(0, 0, -0.45), Vector3(0.22, 0.03, 0.9), steel, Vector3(0, k * 90, 0))
					b.add("box", Vector3(0.18, 0, -0.75), Vector3(0.12, 0.03, 0.4), steel, Vector3(0, k * 90 + 35, 0))
				b.add("cyl", Vector3.ZERO, Vector3(0.25, 0.08, 0.25), dark, Vector3.ZERO, 10)
			"kama":
				b.add("cyl", Vector3(0, 0, 0.1), Vector3(0.05, 0.7, 0.05), Color(0.5, 0.35, 0.2), Vector3(90, 0, 0), 6)
				b.add("box", Vector3(0.16, 0, -0.28), Vector3(0.38, 0.02, 0.08), steel, Vector3(0, -25, 0))
			"katana":
				b.add_grad("box", Vector3(0, 0, -0.6), Vector3(0.06, 0.02, 1.1), steel.lightened(0.1), steel)
				b.add("box", Vector3(0, 0, 0.0), Vector3(0.16, 0.04, 0.06), Color(0.65, 0.55, 0.25))
				b.add("cyl", Vector3(0, 0, 0.2), Vector3(0.05, 0.35, 0.05), Color(0.1, 0.1, 0.12), Vector3(90, 0, 0), 6)
			"sai":
				b.add("cyl", Vector3(0, 0, -0.35), Vector3(0.035, 0.7, 0.035), steel, Vector3(90, 0, 0), 6)
				for sx in [-1.0, 1.0]:
					b.add("cyl", Vector3(0.1 * sx, 0, -0.08), Vector3(0.025, 0.28, 0.025), steel, Vector3(90, 0, 30 * sx), 5)
				b.add("cyl", Vector3(0, 0, 0.12), Vector3(0.04, 0.22, 0.04), wrap, Vector3(90, 0, 0), 6)
			"ono":
				b.add("cyl", Vector3(0, 0, 0.0), Vector3(0.06, 1.1, 0.06), Color(0.45, 0.3, 0.18), Vector3(90, 0, 0), 6)
				b.add("box", Vector3(0.2, 0, -0.45), Vector3(0.42, 0.04, 0.3), steel)
			"kusari":
				b.add("sphere", Vector3(0, 0, -0.2), Vector3(0.36, 0.36, 0.36), dark, Vector3.ZERO, 8)
				for k in 8:
					var a = k * TAU / 8.0
					b.add("cone", Vector3(cos(a) * 0.2, sin(a) * 0.2, -0.2), Vector3(0.07, 0.2, 0.07), steel, Vector3(0, 0, rad_to_deg(a) - 90), 4)
			"chakram":
				b.add("torus", Vector3.ZERO, Vector3(0.55, 0.55, 0.55), steel, Vector3.ZERO, 16)
			"yari":
				b.add("cyl", Vector3(0, 0, 0.3), Vector3(0.04, 1.6, 0.04), Color(0.45, 0.3, 0.18), Vector3(90, 0, 0), 6)
				b.add("cone", Vector3(0, 0, -0.62), Vector3(0.1, 0.4, 0.04), steel, Vector3(-90, 0, 0), 4)
			"tonfa":
				b.add("box", Vector3(0, 0, -0.1), Vector3(0.07, 0.07, 0.75), Color(0.35, 0.22, 0.12))
				b.add("cyl", Vector3(0, -0.12, 0.12), Vector3(0.05, 0.2, 0.05), Color(0.35, 0.22, 0.12), Vector3.ZERO, 6)
			"senbon":
				for k in 3:
					b.add("cyl", Vector3((k - 1) * 0.05, 0, -0.2), Vector3(0.012, 0.6, 0.012), steel, Vector3(90, 0, 0), 4)
		return b)


## Silahı fırlat: from'dan to'ya döne döne uçar; saplandığı yerde kalır (stick), isabet edene hasar
func throw_weapon(c: Node3D, id: String, kind: String, from: Vector3, to: Vector3, speed: float, mul: float, homing: Node3D = null, extra := {}) -> Projectile:
	var d = (to - from).normalized()
	var mi = mi_of(weapon_mesh(kind))
	var info = inf(c, id, mul, {"knock": 2.0, "kind": "light", "hitstop": 0.02}).merged(extra, true)
	var pr = shot(c, from, d, speed, mi, info, homing, false, (from.distance_to(to) / speed) + 0.6)
	pr.radius = 0.35
	pr.stick = true
	if kind in ["shuriken", "fuma", "chakram"]:
		pr.spin = Vector3(0, 28.0, 0)
	elif kind in ["kusari", "ono", "kama", "tonfa"]:
		pr.spin = Vector3(-20.0, 0, 0)
	return pr


## Parşömen: açılmış kâğıt (beyaz, kırmızı kenar) + ahşap rulolar
func scroll_node(w: float, h: float) -> Node3D:
	var mesh = cached("scroll_%d_%d" % [int(w * 10), int(h * 10)], func():
		var b = MB.new()
		b.add("box", Vector3(0, 0, 0), Vector3(w, h, 0.02), Color(0.96, 0.94, 0.86))
		b.add("box", Vector3(0, h * 0.5 - 0.06, -0.012), Vector3(w, 0.1, 0.02), Color(0.75, 0.12, 0.12))
		b.add("box", Vector3(0, -h * 0.5 + 0.06, -0.012), Vector3(w, 0.1, 0.02), Color(0.75, 0.12, 0.12))
		for k in 5:
			b.add("box", Vector3(-w * 0.35 + k * w * 0.17, 0, -0.014), Vector3(0.05, h * 0.55, 0.01), Color(0.1, 0.08, 0.08))
		for sy in [-1.0, 1.0]:
			b.add("cyl", Vector3(0, sy * h * 0.5, 0), Vector3(0.14, w + 0.3, 0.14), Color(0.45, 0.28, 0.15), Vector3(0, 0, 90), 8)
		return b)
	var root = Node3D.new()
	root.add_child(mi_of(mesh))
	return root


## Silah Yağmuru: önünde parşömen açılır, on iki farklı silah art arda fırlar
func p_buki_kuchiyose(c: Node3D, t: Node3D) -> void:
	var d = Jutsu._aim(c, t)
	var fd = fwd(c, t)
	busy(c, 1.2)
	anim(c, "throw", 1.2)
	var sc = scroll_node(1.6, 1.0)
	scene_add(sc, c.global_position + Vector3.UP * 1.3 + fd * 1.1)
	toward(sc, -fd)
	sc.scale = Vector3(0.05, 1, 1)
	var tw = sc.create_tween()
	tw.tween_property(sc, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	fade_free(sc, 1.3, 0.25)
	Sfx.play("poof", sc.global_position, 1.1)
	var tt = tg(c, t, 35.0)
	for k in 12:
		var kind: String = WEAPON_KINDS[k]
		after(0.18 + k * 0.07, func():
			if not is_instance_valid(sc):
				return
			var from = sc.global_position + Vector3(randf_range(-0.5, 0.5), randf_range(-0.3, 0.3), 0) + fd * 0.2
			FX.smoke_puff(from, 0.25, 4)
			var to = (tt.global_position + Vector3.UP * tt.height * 0.5 + Vector3(randf_range(-0.6, 0.6), randf_range(-0.3, 0.4), randf_range(-0.6, 0.6))) if tt and live(tt) else from + d * 30.0 + Vector3(randf_range(-2, 2), randf_range(-1, 1), randf_range(-2, 2))
			throw_weapon(c, "buki_kuchiyose", kind, from, to, 48.0, 0.28 if kind not in ["fuma", "ono", "kusari"] else 0.45, tt if tt and live(tt) else null)
			Sfx.play("kunai", from, randf_range(0.9, 1.3), 0.6))


## Demir Pençe Zinciri: zincir hedefe dolanıp onu sana çeker; hedef yoksa zemine saplanıp seni oraya çeker (kanca)
func p_tesso_kusari(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 26.0)
	var from = hand_pos(c, true)
	var to = tt.global_position + Vector3.UP * tt.height * 0.5 if tt else gp(Jutsu._aim_ground(c, t, 18.0, 26.0)) + Vector3.UP * 0.2
	busy(c, 0.9)
	anim(c, "throw", 1.4)
	var claw_mesh = cached("tesso_claw", func():
		var b = MB.new()
		b.add("sphere", Vector3.ZERO, Vector3(0.3, 0.3, 0.3), Color(0.25, 0.24, 0.26), Vector3.ZERO, 8)
		for k in 3:
			var a = k * TAU / 3.0
			b.add("cone", Vector3(cos(a) * 0.15, sin(a) * 0.15, -0.25), Vector3(0.07, 0.42, 0.07), Color(0.8, 0.82, 0.88), Vector3(-90 + sin(a) * 25, 0, cos(a) * 25), 4)
		return b)
	var claw = mi_of(claw_mesh)
	scene_add(claw, from)
	toward(claw, to - from)
	var chain_mat = Props.toon_color(Color(0.35, 0.34, 0.38))
	tether(func(): return hand_pos(c, true) if is_instance_valid(c) else from, func(): return claw.global_position if is_instance_valid(claw) else from, 0.07, chain_mat, 1.25)
	Sfx.play("clink", from, 1.2)
	var tw = claw.create_tween()
	tw.tween_property(claw, "global_position", to, 0.22)
	tw.tween_callback(func():
		if tt and live(tt):
			hit(c, to, tt.radius + 0.5, inf(c, "tesso_kusari", 0.7, {"knock": 0.0, "kind": "heavy", "hitstop": 0.06}))
			st(tt, "bind", 0.6)
			Combat.popup_text(to + Vector3.UP, "Zincirlendi!", Color(0.85, 0.85, 0.9))
			after(0.15, func():
				if live(tt):
					pull_to(c, tt, 0.35, 1.4)
					st(tt, "stun", 2.0))
			every(0.6, 1.0 / 30.0, func(_i, _k):
				if live(tt) and is_instance_valid(claw):
					claw.global_position = tt.global_position + Vector3.UP * tt.height * 0.5, func():
				if is_instance_valid(claw):
					claw.queue_free())
		else:
			FX.dust(gp(to), 0.6)
			VFX.cracks(gp(to), 1.2)
			# kanca: seni zincirin ucuna çeker
			var start = c.global_position
			if c is Player:
				c.combat.invuln = 0.4
			every(0.35, 1.0 / 40.0, func(_i, k):
				if is_instance_valid(c):
					c.global_position = start.lerp(gp(to), k) + Vector3.UP * sin(k * PI) * 2.0, func():
				if is_instance_valid(claw):
					claw.queue_free()))


## Sōshōryū: iki parşömen ejderha gibi sarmal çizip göğe yükselir; tepede silah yağmuru (60 silah, 10 m yarıçap)
func p_soshoryu(c: Node3D, t: Node3D) -> void:
	var fd = fwd(c, t)
	var center = gp(Jutsu._aim_ground(c, t, 14.0, 30.0))
	busy(c, 2.4)
	if c is Player:
		c.combat.invuln = 1.0
		c.velocity.y = 22.0
	var base = c.global_position
	VFX.slowmo(0.6, 0.5)
	Sfx.play("poof", base, 0.8)
	for k in 2:
		var head = Node3D.new()
		scene_add(head, base)
		var sc = scroll_node(0.5, 0.35)
		head.add_child(sc)
		VFX.trail(head, 0.9, Color(1, 1, 0.97), Color(0.97, 0.94, 0.85), Color(0.85, 0.2, 0.2, 0.0), 26)
		every(1.0, 1.0 / 40.0, func(_i, kk):
			if not is_instance_valid(head):
				return
			var a = kk * TAU * 2.2 + k * PI
			head.global_position = base + Vector3(cos(a) * (2.5 + kk * 2.0), 1.0 + kk * 19.0, sin(a) * (2.5 + kk * 2.0))
			head.rotate_y(0.3), Callable())
		fade_free(head, 2.6, 0.3)
	var sky = base + Vector3.UP * 20.0
	for k in 60:
		after(0.9 + k * 0.025, func():
			var kind: String = WEAPON_KINDS[k % WEAPON_KINDS.size()]
			var land = center + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
			land = gp(land)
			var from = sky + Vector3(randf_range(-3, 3), randf_range(-1, 2), randf_range(-3, 3))
			var pr = throw_weapon(c, "soshoryu", kind, from, land + Vector3.UP * 0.1, 55.0, 0.22)
			pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
				hit(c, pos, 1.4, inf(c, "soshoryu", 0.18, {"knock": 2.0, "kind": "light"}))
				FX.dust(pos, 0.35)
			if k % 6 == 0:
				Sfx.play("kunai", from, randf_range(0.8, 1.2), 0.7))
	after(1.0, func():
		FX.ring(center + Vector3.UP * 0.1, Color(0.95, 0.9, 0.8), 20.0, 0.6, true)
		shake(0.5))


## Demir Yelpaze: dev demir yelpaze açılır, 6 sn mermileri durdurur; kapanırken savurduğu rüzgar düşmanları uçurur
func p_tekkosen(c: Node3D, t: Node3D) -> void:
	var fd = fwd(c, t)
	busy(c, 0.6)
	var mesh = cached("tekkosen", func():
		var b = MB.new()
		for k in 11:
			var a = deg_to_rad(-80.0 + k * 16.0)
			b.add_grad("box", Vector3(sin(a) * 2.2, cos(a) * 2.2, 0), Vector3(0.55, 4.4, 0.08), Color(0.42, 0.42, 0.46), Color(0.2, 0.2, 0.24), Vector3(0, 0, -rad_to_deg(a)))
			b.add("sphere", Vector3(sin(a) * 4.4, cos(a) * 4.4, 0), Vector3(0.28, 0.28, 0.12), Color(0.85, 0.7, 0.25), Vector3.ZERO, 6)
		b.add("cyl", Vector3(0, 0, 0), Vector3(0.6, 0.25, 0.6), Color(0.8, 0.65, 0.25), Vector3(90, 0, 0), 12)
		b.add("box", Vector3(0, 1.8, -0.06), Vector3(5.6, 0.18, 0.04), Color(0.7, 0.12, 0.12))
		return b)
	var fan = mi_of(mesh)
	fan.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var root = Node3D.new()
	scene_add(root, gp(c.global_position + fd * 2.4))
	toward(root, -fd)
	root.add_child(fan)
	fan.position = Vector3(0, 0.4, 0)
	fan.scale = Vector3(0.05, 1, 1)
	var tw = fan.create_tween()
	tw.tween_property(fan, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	var cs = CollisionShape3D.new()
	var bx = BoxShape3D.new()
	bx.size = Vector3(8.0, 4.8, 0.8)
	cs.shape = bx
	cs.position = Vector3(0, 2.6, 0)
	sb.add_child(cs)
	root.add_child(sb)
	Sfx.play("clink", root.global_position, 0.6)
	every(6.0, 0.05, func(_i, _k):
		if not is_instance_valid(root):
			return
		for pr in get_tree().get_nodes_in_group("projectiles"):
			if pr is Projectile and is_instance_valid(pr) and pr.shooter != c and pr.global_position.distance_to(root.global_position + Vector3.UP * 2.5) < 4.8:
				FX.hit_spark(pr.global_position, Color(1, 0.9, 0.6), 1.0)
				Sfx.play("clink", pr.global_position, 1.3, 0.6)
				pr.queue_free(), func():
		if not is_instance_valid(root):
			return
		var t2 = fan.create_tween()
		t2.tween_property(fan, "rotation:y", PI * 0.5, 0.2)
		t2.tween_callback(root.queue_free)
		var wd = fd
		if is_instance_valid(c):
			wd = c.face_dir()
		VFX.shockwave(root.global_position + Vector3.UP * 1.5, Color(0.85, 0.95, 1.0), 12.0, 0.35, false, wd)
		Sfx.play("wind", root.global_position, 0.9)
		for e in enemies_near(c, root.global_position + wd * 6.0, 8.0):
			hit(c, e.global_position + Vector3.UP, e.radius + 0.5, inf(c, "tekkosen", 0.9, {"knock": 24.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.05})))


## Telli Silah Fırtınası: 10 silah tellerle etrafında döner; her 0.45 sn ikisi en yakın düşmanlara saplanıp geri döner, tele dolanan bağlanır
func p_ito_buki_arashi(c: Node3D, _t: Node3D) -> void:
	var dur = 7.0
	busy(c, 0.5)
	var wire = glow(Color(0.75, 0.9, 1.0), 0.75)
	var ws = []
	for k in 10:
		var w = Node3D.new()
		w.add_child(mi_of(weapon_mesh(WEAPON_KINDS[k % WEAPON_KINDS.size()])))
		scene_add(w, c.global_position + Vector3.UP)
		ws.append({"n": w, "a": TAU * k / 10.0, "busy": 0.0})
		var wn = w
		tether(func(): return hand_pos(c, k % 2 == 0) if is_instance_valid(c) else Vector3.ZERO, func(): return wn.global_position if is_instance_valid(wn) else Vector3.ZERO, 0.025, wire, dur)
	Sfx.play("whoosh", c.global_position, 0.9)
	var acc = {"t": 0.0}
	every(dur, 1.0 / 30.0, func(_i, kk):
		if not is_instance_valid(c):
			return
		acc["t"] += 1.0 / 30.0
		var tt = Time.get_ticks_msec() * 0.001
		for w in ws:
			var n: Node3D = w["n"]
			if not is_instance_valid(n):
				continue
			if w["busy"] > 0.0:
				w["busy"] -= 1.0 / 30.0
				continue
			var a = w["a"] + tt * 3.2
			var rest = c.global_position + Vector3(cos(a) * 3.2, 1.2 + sin(tt * 2.0 + w["a"]) * 0.5, sin(a) * 3.2)
			n.global_position = n.global_position.lerp(rest, 0.35)
			toward(n, Vector3(-sin(a), 0, cos(a)))
			for e in enemies_near(c, n.global_position, 0.9):
				hit(c, n.global_position, 1.0, inf(c, "ito_buki_arashi", 0.08, {"knock": 1.5, "kind": "light", "hitstop": 0.0}))
		if acc["t"] >= 0.45:
			acc["t"] = 0.0
			var near = enemies_near(c, c.global_position, 16.0)
			if near.is_empty():
				return
			var sent = 0
			for w in ws:
				if sent >= 2 or w["busy"] > 0.0 or not is_instance_valid(w["n"]):
					continue
				var e = near[(sent + int(tt * 10.0)) % near.size()]
				var n: Node3D = w["n"]
				w["busy"] = 0.5
				sent += 1
				var from = n.global_position
				var to = e.global_position + Vector3.UP * e.height * 0.5
				var tw = n.create_tween()
				tw.tween_property(n, "global_position", to, 0.14)
				tw.tween_callback(func():
					if live(e):
						hit(c, to, e.radius + 0.5, inf(c, "ito_buki_arashi", 0.32, {"knock": 2.0, "kind": "light", "hitstop": 0.03}))
						st(e, "bind", 0.6)
						Sfx.play("kunai", to, 1.2, 0.5))
				tw.tween_property(n, "global_position", from, 0.2), func():
		for w in ws:
			if is_instance_valid(w["n"]):
				FX.smoke_puff(w["n"].global_position, 0.3, 4)
				w["n"].queue_free())


## Dev Demir Topuz: gökte çağırma çemberi açılır, çivili dev topuz düşüp krater açar
func p_kuchiyose_tetsuzan(c: Node3D, t: Node3D) -> void:
	var center = gp(Jutsu._aim_ground(c, t, 14.0, 32.0))
	busy(c, 0.8)
	var sky = center + Vector3.UP * 28.0
	ground_disc(sky, 6.0, Color(0.85, 0.3, 0.25), 1.0, 2, 12).global_position = sky
	ground_disc(center, 8.0, Color(1.0, 0.4, 0.3), 1.0, 1, 0)
	Sfx.play("poof", sky, 0.6)
	var mesh = cached("tetsuzan", func():
		var b = MB.new()
		b.add_grad("sphere", Vector3.ZERO, Vector3(7.0, 7.0, 7.0), Color(0.36, 0.35, 0.38), Color(0.15, 0.14, 0.16), Vector3.ZERO, 16)
		for k in 22:
			var a = k * 2.4
			var y = -0.9 + 1.8 * float(k) / 21.0
			var r = sqrt(maxf(0.0, 1.0 - y * y))
			var dir = Vector3(cos(a) * r, y, sin(a) * r).normalized()
			var basis = Basis(Quaternion(Vector3.UP, dir))
			var e = basis.get_euler()
			b.add("cone", dir * 3.6, Vector3(0.9, 2.2, 0.9), Color(0.75, 0.75, 0.8), Vector3(rad_to_deg(e.x), rad_to_deg(e.y), rad_to_deg(e.z)), 5)
		b.add("box", Vector3(0, 3.6, 0), Vector3(0.6, 1.4, 0.6), Color(0.3, 0.28, 0.3))
		b.add("torus", Vector3(0, 4.5, 0), Vector3(1.4, 1.4, 1.4), Color(0.3, 0.28, 0.3), Vector3(90, 0, 0), 10)
		return b)
	var ball = mi_of(mesh)
	ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	scene_add(ball, sky)
	ball.scale = Vector3.ONE * 0.2
	var tw = ball.create_tween()
	tw.tween_property(ball, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(ball, "global_position", center + Vector3.UP * 2.2, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		VFX.slowmo(0.5, 0.25)
		shake(1.3)
		VFX.cracks(center, 14.0)
		VFX.debris(center, Color(0.45, 0.38, 0.3), 30, 18.0, 0.9)
		FX.dust(center, 3.5)
		VFX.shockwave(center + Vector3.UP * 0.3, Color(0.85, 0.75, 0.6), 28.0, 0.5, true)
		Sfx.play("boom", center, 0.6)
		hit(c, center + Vector3.UP, 8.5, inf(c, "kuchiyose_tetsuzan", 2.4, {"knock": 18.0, "launch": 12.0, "kind": "heavy", "hitstop": 0.14})))
	tw.tween_interval(3.0)
	tw.tween_callback(func(): FX.smoke_puff(ball.global_position, 3.0, 18))
	tw.tween_property(ball, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(ball.queue_free)


## Bashōsen: palmiye yaprağı biçimli efsanevi yelpaze elde belirir; her sargı ayrı bir doğa — ek chakra emer
func bashosen_fan(c: Node3D, el_col: Color) -> Node3D:
	var mesh = cached("bashosen", func():
		var b = MB.new()
		b.add_grad("sphere", Vector3(0, 1.3, 0), Vector3(1.5, 1.9, 0.08), Color(0.78, 0.82, 0.45), Color(0.45, 0.55, 0.22), Vector3.ZERO, 14)
		for k in 7:
			b.add("box", Vector3((k - 3) * 0.18, 1.25, -0.05), Vector3(0.03, 1.7, 0.02), Color(0.4, 0.45, 0.2), Vector3(0, 0, (k - 3) * 9))
		b.add("cyl", Vector3(0, 0.0, 0), Vector3(0.09, 0.8, 0.09), Color(0.35, 0.2, 0.12), Vector3.ZERO, 8)
		b.add("sphere", Vector3(0, -0.45, 0), Vector3(0.22, 0.26, 0.22), Color(0.75, 0.55, 0.2), Vector3.ZERO, 8)   # su kabağı topuzu
		b.add("box", Vector3(0, -0.6, 0), Vector3(0.05, 0.25, 0.05), Color(0.8, 0.15, 0.15))
		return b)
	var root = Node3D.new()
	var mi = mi_of(mesh)
	root.add_child(mi)
	var rim = MeshInstance3D.new()
	rim.mesh = VFX._sphere(0.5, 16, 8)
	rim.material_override = glow(el_col, 0.45)
	rim.scale = Vector3(1.75, 2.1, 0.2)
	rim.position = Vector3(0, 1.3, 0)
	root.add_child(rim)
	var ba = bone_attach(c, "RightHand")
	if ba:
		ba.add_child(root)
		root.rotation_degrees = Vector3(-90, 0, 0)
	else:
		scene_add(root, hand_pos(c, true))
	root.scale = Vector3.ONE * 0.05
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE * 1.25, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.4)
	tw.tween_property(root, "scale", Vector3.ONE * 0.05, 0.25)
	tw.tween_callback(func():
		if is_instance_valid(ba):
			ba.queue_free()
		elif is_instance_valid(root):
			root.queue_free())
	if c is Player:
		c.chakra = maxf(0.0, c.chakra - c.max_chakra * 0.15)
		Combat.popup_text(c.global_position + Vector3.UP * 2.4, "Bashōsen chakranı emiyor!", Color(0.95, 0.85, 0.5))
	busy(c, 1.1)
	anim(c, "slash_a", 1.0)
	return root


func p_bashosen_kaze_no_maki(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	bashosen_fan(c, Color(0.7, 1.0, 0.85))
	after(0.35, func():
		var tor = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 7.5
		cm.bottom_radius = 1.4
		cm.height = 26.0
		cm.radial_segments = 20
		cm.rings = 6
		tor.mesh = cm
		tor.material_override = VFX.mat_wind(Color(0.8, 1.0, 0.92), 9.0, 7.0, Vector3.UP, 0.8)
		var start = gp(c.global_position + d * 4.0)
		scene_add(tor, start + Vector3.UP * 13.0)
		Sfx.play("wind", start, 0.6)
		shake(0.6)
		var hits = {}
		every(3.0, 1.0 / 30.0, func(i, k):
			if not is_instance_valid(tor):
				return
			var p = gp(start + d * (k * 42.0)) + Vector3.UP * 13.0
			tor.global_position = p
			tor.rotate_y(0.6)
			var base = p - Vector3.UP * 12.0
			if i % 4 == 0:
				FX.dust(base, 2.0)
			for e in enemies_near(c, base, 6.5):
				if live(e):
					e.global_position = e.global_position.lerp(base + Vector3.UP * minf(10.0, 2.0 + hits.get(e, 0) * 0.4), 0.15)
					hits[e] = hits.get(e, 0) + 1
					if hits[e] % 6 == 1:
						hit(c, e.global_position + Vector3.UP, e.radius + 0.6, inf(c, "bashosen_kaze_no_maki", 0.35, {"element": "fuuton", "knock": 4.0, "launch": 4.0, "kind": "heavy"})), func():
			if is_instance_valid(tor):
				fade_free(tor, 0.0, 0.4)))


func p_bashosen_hi_no_maki(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var side = d.cross(Vector3.UP).normalized()
	bashosen_fan(c, Color(1.0, 0.55, 0.15))
	after(0.35, func():
		var wall = Node3D.new()
		var start = gp(c.global_position + d * 4.0)
		scene_add(wall, start)
		toward(wall, d)
		for n in 11:
			var cm = CylinderMesh.new()
			cm.top_radius = 0.3; cm.bottom_radius = 1.2; cm.height = 1.0; cm.radial_segments = 12; cm.rings = 4
			cm.cap_top = false; cm.cap_bottom = false
			var col = VFX._mi(cm, VFX.mat_fire("fire", 3.2, 1.8, 0.4, 1.4, 0.24, Vector3.UP, true))
			wall.add_child(col)
			var hh = 8.0 - absf(n - 5) * 0.55
			col.position = Vector3((n - 5) * 2.1, hh * 0.5, absf(n - 5) * 0.35)
			col.scale = Vector3(2.0, 0.1, 2.0)
			var ct = col.create_tween()
			ct.tween_interval(absf(n - 5) * 0.03)
			ct.tween_property(col, "scale", Vector3(2.0, hh, 2.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sfx.play("fire", start, 0.6)
		shake(0.7)
		var hits = {}
		every(2.4, 1.0 / 30.0, func(i, k):
			if not is_instance_valid(wall):
				return
			var p = gp(start + d * (k * 36.0))
			wall.global_position = p
			if i % 3 == 0:
				VFX.embers(p + side * randf_range(-10, 10) + Vector3.UP * 2.0, Color(1, 0.55, 0.15), 10, 10.0)
				if i % 9 == 0:
					VFX.black_smolder(p + side * randf_range(-9, 9), 1.6, 3.0)
			for e in enemies_near(c, p + Vector3.UP, 11.5):
				var rel = e.global_position - p
				if absf(rel.dot(d)) < 2.5 and not hits.has(e):
					hits[e] = true
					hit(c, e.global_position + Vector3.UP, e.radius + 0.6, inf(c, "bashosen_hi_no_maki", 1.6, {"element": "katon", "burn": 6.0, "knock": 12.0, "launch": 5.0, "kind": "heavy"})), func():
			if is_instance_valid(wall):
				fade_free(wall, 0.0, 0.4)))


func p_bashosen_rai_no_maki(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var side = d.cross(Vector3.UP).normalized()
	bashosen_fan(c, Color(0.6, 0.8, 1.0))
	var center = gp(c.global_position + d * 16.0)
	after(0.35, func():
		var field = ground_disc(center, 13.0, Color(0.55, 0.75, 1.0), 4.4, 3, 16)
		field.scale = Vector3(1.0, 1, 1.0)
		Sfx.play("thunder", center, 0.7)
		every(4.0, 0.35, func(i, _k):
			for k in 5:
				var p = center + d * randf_range(-11, 11) + side * randf_range(-11, 11)
				var g = gp(p)
				var near = enemies_near(c, center, 13.0)
				if k < 2 and not near.is_empty():
					g = near[(i + k) % near.size()].global_position
				VFX.bolt(g + Vector3.UP * 26.0 + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)), g, Color(0.6, 0.8, 1.0), 0.35, 0.2, 4)
				FX.ring(g + Vector3.UP * 0.1, Color(0.6, 0.85, 1.0), 3.0, 0.25, true)
				for e in enemies_near(c, g, 2.4):
					hit(c, e.global_position + Vector3.UP, e.radius + 0.5, inf(c, "bashosen_rai_no_maki", 0.35, {"element": "raiton", "knock": 2.0, "kind": "light", "hitstop": 0.04}))
					st(e, "stun", 0.6)
			if i % 2 == 0:
				shake(0.25), Callable()))


func p_bashosen_mizu_no_maki(c: Node3D, t: Node3D) -> void:
	var d = fwd(c, t)
	var side = d.cross(Vector3.UP).normalized()
	bashosen_fan(c, Color(0.4, 0.7, 1.0))
	after(0.35, func():
		var wave = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 2.5
		cm.bottom_radius = 5.0
		cm.height = 24.0
		cm.radial_segments = 16
		wave.mesh = cm
		wave.material_override = VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.8, 0.95, 1.0), d, 0.9, 0.7, 0.08)
		var start = gp(c.global_position + d * 3.0)
		scene_add(wave, start + Vector3.UP * 2.6)
		wave.look_at(wave.global_position + side, Vector3.UP)
		wave.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		Sfx.play("water", start, 0.6)
		shake(0.6)
		every(2.6, 1.0 / 30.0, func(i, k):
			if not is_instance_valid(wave):
				return
			var p = gp(start + d * (k * 38.0))
			wave.global_position = p + Vector3.UP * (2.6 + sin(k * PI) * 1.5)
			if i % 3 == 0:
				VFX.splash(p + side * randf_range(-10, 10), 2.4)
			for e in enemies_near(c, p, 12.0):
				var rel = e.global_position - p
				if absf(rel.dot(d)) < 3.5 and live(e):
					e.global_position = gp(e.global_position + d * 0.9)
					if i % 5 == 0:
						hit(c, e.global_position + Vector3.UP, e.radius + 0.6, inf(c, "bashosen_mizu_no_maki", 0.4, {"element": "suiton", "knock": 3.0, "kind": "heavy"}))
						st(e, "wet", 8.0), func():
			if is_instance_valid(wave):
				fade_free(wave, 0.0, 0.4)
				VFX.splash(wave.global_position, 4.0)))


# ================================================================== Şifacı Yolu (Tıbbi Ninja)
const MED := Color(0.45, 0.95, 0.6)


## Toprak Gizlenmesi: yere gömülür (görünmez, darbe almaz), 3 sn sonra hedefin dibinden yukarı fırlayıp çene darbesi
func p_senpuku(c: Node3D, t: Node3D) -> void:
	busy(c, 0.4)
	anim(c, "crouch", 1.6)
	FX.dust(c.global_position, 1.2)
	Sfx.play("earth", c.global_position, 0.8)
	var m = c.get("model")
	if m:
		m.create_tween().tween_property(m, "position:y", -2.0, 0.35)
	if c is Player:
		Buffs.add("stealth_senpuku", 3.0, {"stealth": 1.0, "armor": 0.0, "_desc": "Yerin altındasın: görünmez, hasar almazsın"})
	after(3.0, func():
		if not live(c):
			return
		var tt = tg(c, t, 14.0)
		if tt:
			c.global_position = gp(tt.global_position + fwd(c, tt) * -0.8)
		if m:
			m.create_tween().tween_property(m, "position:y", 0.0, 0.15)
		VFX.puffs(c.global_position, {"amount": 30, "life": 0.7, "size": 0.8, "radius": 1.0, "vmin": 4, "vmax": 9, "dir": Vector3.UP, "spread": 30.0,
			"colors": [Color(0.6, 0.5, 0.38, 0.9), Color(0.5, 0.42, 0.32, 0)]})
		anim(c, "hook", 1.6)
		Sfx.play("hit_heavy", c.global_position, 0.9)
		hit(c, c.global_position + Vector3.UP * 1.0, 2.0, inf(c, "senpuku", 1.0, {"launch": 9.0, "knock": 4.0, "kind": "heavy"})))


## Ceset Diriltme: solgun, dikişli bir ceset ayağa kalkar ve 20 sn senin için savaşır
func p_shikon_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.6)
	var at = gp(c.global_position + fwd(c, t) * 3.0)
	summon_circle(at, 1.6, Color(0.5, 0.75, 0.55), 1.2)
	after(0.5, func():
		if not live(c):
			return
		var d = ShadowClone.new()
		d.team = c.team
		var lk = CharacterModel.default_look()
		lk.merge({"skin": Color(0.72, 0.74, 0.7), "top": Color(0.35, 0.33, 0.3), "top2": Color(0.3, 0.28, 0.26), "pants": Color(0.25, 0.24, 0.22),
			"hair": Color(0.3, 0.3, 0.3), "face_mark": "kırışık", "band_style": "slashed"}, true)
		d.look = lk
		d.life = 20.0
		get_tree().current_scene.add_child(d)
		d.global_position = at
		d.max_hp = 1.0
		FX.burst(at + Vector3.UP, {"amount": 26, "life": 0.8, "tex": FX.tex_smoke, "add": false, "size": 0.7, "vmin": 1, "vmax": 3, "colors": [Color(0.55, 0.7, 0.55, 0.8), Color(0.4, 0.5, 0.4, 0)]})
		Combat.popup_text(at + Vector3.UP * 2.4, "Ceset kalktı!", Color(0.6, 0.85, 0.6)))


## Zehir Çekme: avuçta dönen su küresi bedenden mor zehri çeker; zehir/yavaşlama/bağ biter, can yenilenir
func p_saikan_chushutsu_no_jutsu(c: Node3D, _t: Node3D) -> void:
	busy(c, 1.2)
	anim(c, "cast", 1.0)
	var orb = MeshInstance3D.new()
	orb.mesh = VFX._sphere(0.22, 16, 8)
	orb.material_override = VFX.mat_water(Color(0.15, 0.55, 0.65), Color(0.4, 0.85, 0.8), Color(0.85, 1, 0.95), Vector3.UP, 0.4, 0.6, 0.1)
	get_tree().current_scene.add_child(orb)
	every(1.1, 1.0 / 30.0, func(_i, k):
		if is_instance_valid(orb) and live(c):
			orb.global_position = hand_pos(c, true) + Vector3.UP * 0.15
			orb.scale = Vector3.ONE * (0.6 + k * 0.8)
			if randf() < 0.5:
				VFX.puffs(c.global_position + Vector3.UP * randf_range(0.6, 1.5), {"amount": 2, "life": 0.4, "size": 0.15, "radius": 0.2, "vmin": 1, "vmax": 2,
					"colors": [Color(0.55, 0.2, 0.65, 0.9), Color(0.4, 0.1, 0.5, 0)]}), func():
		if is_instance_valid(orb):
			FX.burst(orb.global_position, {"amount": 20, "life": 0.5, "tex": FX.tex_smoke, "add": false, "size": 0.3, "vmin": 2, "vmax": 4, "gravity": Vector3(0, -8, 0), "colors": [Color(0.5, 0.2, 0.6, 0.9), Color(0.3, 0.1, 0.4, 0)]})
			orb.queue_free()
		if live(c):
			for s in ["poison", "slow", "bind", "stun", "burn"]:
				if c.has_method("clear_status"):
					c.clear_status(s)
				elif "statuses" in c:
					c.statuses.erase(s)
			heal(c, c.max_hp * 0.25)
			Combat.popup_text(c.global_position + Vector3.UP * 2.6, "Zehir çekildi", MED))


## Zehir Sisi: ağızdan mor sis yelpazesi; 7 sn yerde kalır, içindekiler zehirlenir ve yavaşlar
func p_dokugiri(c: Node3D, t: Node3D) -> void:
	busy(c, 0.7)
	var d = fwd(c, t)
	var center = gp(c.global_position + d * 6.0)
	Sfx.play("wind", c.global_position, 0.6)
	for k in 5:
		after(k * 0.08, func():
			VFX.puffs(c.global_position + Vector3.UP * 1.5 + d * (1.0 + k * 1.4), {"amount": 26, "life": 1.4, "size": 1.4 + k * 0.3, "radius": 0.6 + k * 0.4, "vmin": 2, "vmax": 5, "dir": d, "spread": 25.0,
				"colors": [Color(0.55, 0.25, 0.65, 0.75), Color(0.35, 0.15, 0.45, 0)]}))
	every(7.0, 0.5, func(_i, _k):
		VFX.puffs(center + Vector3.UP * 0.8, {"amount": 8, "life": 1.2, "size": 1.8, "radius": 4.0, "vmin": 0.2, "vmax": 0.8, "colors": [Color(0.55, 0.25, 0.65, 0.5), Color(0.35, 0.15, 0.45, 0)]})
		for e in enemies_near(c, center, 5.0):
			st(e, "slow", 1.0)
			e.take_hit(inf(c, "dokugiri", 0.12, {"knock": 0.0, "kind": "light", "element": ""})), Callable())


## Sinir Karıştırma: elektrikli yeşil avuç darbesi; hedefin sinirleri karışır (3 sn sersem, sonra yavaş)
func p_ranshinsho(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	busy(c, 0.6)
	anim(c, "jab", 1.6)
	var pt = hand_pos(c, true)
	FX.burst(pt, {"amount": 30, "life": 0.35, "tex": FX.tex_spark, "add": true, "size": 0.25, "vmin": 2, "vmax": 7, "colors": [Color(0.6, 1, 0.7), Color(0.3, 1, 0.5, 0)]})
	Sfx.play("chidori", pt, 1.6, 0.4)
	if tt and tt.global_position.distance_to(c.global_position) < 4.0:
		tt.take_hit(inf(c, "ranshinsho", 0.6, {"knock": 1.0, "kind": "light"}))
		st(tt, "stun", 3.0)
		after(3.0, func(): st(tt, "slow", 4.0))
		Combat.popup_text(tt.global_position + Vector3.UP * 2.4, "Sinirler karıştı!", Color(0.6, 1, 0.7))


## Chakra Neşteri: iki elde mavi parlayan bıçak (12 sn); yakın dövüş güçlenir, vurulan kas kesilir (yavaşlar)
func p_chakura_no_mesu(c: Node3D, _t: Node3D) -> void:
	anim(c, "cast", 1.4)
	var blades = []
	for right in [true, false]:
		var ba = bone_attach(c, "RightHand" if right else "LeftHand")
		if ba == null:
			continue
		var b = MB.new()
		b.add("box", Vector3(0, 0.12, 0.02), Vector3(0.02, 0.22, 0.07), Color(0.6, 0.9, 1.0))
		var mi = mesh_of(b, glow(Color(0.55, 0.9, 1.0), 0.8))
		ba.add_child(mi)
		blades.append(ba)
	Sfx.play("chidori", c.global_position, 2.0, 0.3)
	if c is Player:
		Buffs.add("chakura_no_mesu", 12.0, {"melee": 1.5, "_name": "Chakra Neşteri", "_desc": "vurduğun düşman yavaşlar (kas kesildi)"})
	every(12.0, 0.25, func(_i, _k):
		for e in enemies_near(c, c.global_position, 2.2):
			if randf() < 0.25:
				st(e, "slow", 2.0), func():
		for ba in blades:
			if is_instance_valid(ba):
				ba.queue_free())


## Hücre Yenileme: bedeni saran yeşil ışık, 15 sn her saniye %4 can
func p_in_yu_shometsu(c: Node3D, _t: Node3D) -> void:
	anim(c, "cast", 1.2)
	var a = FX.aura(c, MED, 1.1, Vector3(0, 0.9, 0), 0.0)
	if c is Player:
		Buffs.add("in_yu_shometsu", 15.0, {"_name": "Hücre Yenileme", "_desc": "her sn canın %4'ü yenilenir"})
	every(15.0, 1.0, func(_i, _k):
		if live(c):
			heal(c, c.max_hp * 0.04), func():
		if is_instance_valid(a):
			a.emitting = false)


## Yaradılış Yenilenmesi: alında elmas mühür açılır, yüze/kollara mühür çizgileri yayılır; tam iyileşme + 20 sn güçlü yenilenme
func p_sozo_saisei(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.8)
	anim(c, "cast", 0.9)
	var m = c.get("model")
	var parts = []
	var hb = bone_attach(c, "Head")
	if hb:
		var b = MB.new()
		b.add("box", Vector3(0, 0.1, 0.1), Vector3(0.025, 0.025, 0.008), Color(0.6, 0.2, 0.75), Vector3(0, 0, 45))   # Byakugō elması
		var mi = mesh_of(b, glow(Color(0.65, 0.25, 0.85), 1.0))
		hb.add_child(mi)
		parts.append(hb)
	for bone in ["LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "Neck"]:
		var ba = bone_attach(c, bone)
		if ba == null:
			continue
		var b2 = MB.new()
		for k in 3:
			b2.add("box", Vector3(0.045 * (1 if k % 2 == 0 else -1), 0.05 + k * 0.07, 0.03), Vector3(0.008, 0.06, 0.004), Color(0.25, 0.1, 0.35), Vector3(0, 0, 25 - k * 25))
		ba.add_child(mesh_of(b2, glow(Color(0.35, 0.12, 0.45), 1.0)))
		parts.append(ba)
	FX.ring(c.global_position + Vector3.UP * 1.0, Color(0.7, 0.3, 0.9), 4.0, 0.5)
	Sfx.play("heal", c.global_position, 0.8)
	heal(c, c.max_hp)
	if c is Player:
		Buffs.add("sozo_saisei", 20.0, {"armor": 0.85, "_name": "Yaradılış Yenilenmesi", "_desc": "tam iyileşme + her sn canın %6'sı yenilenir"})
	every(20.0, 1.0, func(_i, _k):
		if live(c):
			heal(c, c.max_hp * 0.06), func():
		for pp in parts:
			if is_instance_valid(pp):
				pp.queue_free())


# ================================================================== Sekiz Kapı Yolu
const GATE_GREEN := Color(0.45, 1.0, 0.45)


func _gate_cost(c: Node3D, frac: float) -> void:
	if c is Player:
		c.hp = maxf(1.0, c.hp - c.max_hp * frac)
	FX.aura(c, GATE_GREEN, 1.0, Vector3(0, 0.9, 0), 0.8)


## Ön Lotus: hedefe atıl, çeneden yukarı tekmele, havada sargıyla sar ve başaşağı yere çak
func p_omote_renge(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 12.0)
	_gate_cost(c, 0.05)
	busy(c, 1.4)
	if tt == null:
		anim(c, "hook", 1.5)
		return
	c.global_position = gp(tt.global_position - fwd(c, tt) * 1.0)
	anim(c, "hook", 1.8)
	Sfx.play("hit_heavy", c.global_position, 1.1)
	tt.take_hit(inf(c, "omote_renge", 0.3, {"launch": 14.0, "knock": 0.0, "kind": "heavy"}))
	after(0.45, func():
		if not live(tt):
			return
		# sargı: hedefle aradaki beyaz bant
		tether(func(): return c.global_position + Vector3.UP * 1.2, func(): return tt.global_position + Vector3.UP, 0.08, glow(Color(0.95, 0.94, 0.9), 1.0), 0.5)
		c.global_position = tt.global_position + Vector3.UP * 0.5
		anim(c, "air", 1.4))
	after(0.95, func():
		if not live(c):
			return
		var p = gp(c.global_position)
		c.global_position = p
		if live(tt):
			tt.global_position = p
		FX.impact(p, GATE_GREEN, 2.0)
		FX.ring(p + Vector3.UP * 0.1, Color(0.7, 0.65, 0.55), 6.0, 0.4)
		shake(0.7)
		Sfx.play("boom", p, 0.8)
		hit(c, p + Vector3.UP * 0.6, 3.0, inf(c, "omote_renge", 1.4, {"knock": 8.0, "kind": "heavy"})))


## Arka Lotus: üçüncü kapı; hedefi havaya savurup arkasından görünerek 6 hızlı vuruş, son yumrukla yere çakar
func p_ura_renge(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	_gate_cost(c, 0.1)
	busy(c, 1.8)
	if tt == null:
		return
	c.global_position = gp(tt.global_position - fwd(c, tt) * 1.0)
	tt.take_hit(inf(c, "ura_renge", 0.2, {"launch": 16.0, "knock": 0.0, "kind": "heavy"}))
	for k in 6:
		after(0.25 + k * 0.13, func():
			if not live(tt) or not live(c):
				return
			var side = Vector3(cos(k * 2.1), 0.4, sin(k * 2.1)) * 1.2
			c.global_position = tt.global_position + side
			anim(c, ["jab", "cross", "hook"][k % 3], 2.2)
			FX.impact(tt.global_position + Vector3.UP * 0.8, GATE_GREEN, 0.8)
			Sfx.play("punch", tt.global_position, 1.2 + k * 0.05)
			tt.take_hit(inf(c, "ura_renge", 0.22, {"knock": 0.0, "launch": 2.0, "kind": "light", "hitstop": 0.03})))
	after(1.15, func():
		if not live(c):
			return
		var p = gp(tt.global_position if live(tt) else c.global_position)
		c.global_position = p + Vector3.UP * 0.2
		if live(tt):
			tt.global_position = p
		anim(c, "cross", 1.4)
		FX.impact(p, GATE_GREEN, 3.0)
		FX.ring(p + Vector3.UP * 0.1, Color(0.7, 0.65, 0.55), 9.0, 0.5)
		shake(1.1)
		Sfx.play("boom", p, 0.6)
		hit(c, p + Vector3.UP * 0.6, 4.0, inf(c, "ura_renge", 1.8, {"knock": 12.0, "kind": "heavy"})))


## Sekiz Kapı Açılışı: yeşil buhar fışkırır, ten kızarır; 25 sn büyük güç ve hız, can yavaşça erir
func p_hachimon_tonko_no_jin(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.8)
	anim(c, "cast", 1.0)
	shake(0.8)
	Sfx.play("roar", c.global_position, 1.2, 0.6)
	FX.ring(c.global_position + Vector3.UP * 0.2, GATE_GREEN, 10.0, 0.5)
	var a = FX.aura(c, GATE_GREEN, 1.6, Vector3(0, 0.9, 0), 0.0)
	var m = c.get("model")
	var skin_mats = []
	if m:
		var ratio: Color = m._skin_ratio()
		for sm in m.materials:
			if sm is ShaderMaterial and sm.get_shader_parameter("tint") == ratio:
				skin_mats.append(sm)
				sm.set_shader_parameter("tint", ratio * Color(1.15, 0.78, 0.72))   # kapılar açıkken ten kızarır
	if c is Player:
		Buffs.add("hachimon", 25.0, {"melee": 2.1, "speed": 1.5, "_name": "Sekiz Kapı Açık", "_desc": "her sn canın %1.5'i erir"})
	every(25.0, 0.4, func(_i, _k):
		if live(c):
			if c is Player:
				c.hp = maxf(1.0, c.hp - c.max_hp * 0.006)
			VFX.puffs(c.global_position + Vector3.UP * 1.2, {"amount": 3, "life": 0.8, "size": 0.6, "radius": 0.4, "vmin": 1, "vmax": 3, "dir": Vector3.UP, "spread": 30.0,
				"colors": [Color(0.75, 1, 0.75, 0.6), Color(0.6, 0.9, 0.6, 0)]}), func():
		if is_instance_valid(a):
			a.emitting = false
		if m and is_instance_valid(m):
			for sm in skin_mats:
				sm.set_shader_parameter("tint", m._skin_ratio()))


## Sabah Tavuskuşu: altıncı kapı; sürtünmeden alev alan yumruklar tavuskuşu kuyruğu gibi yelpazelenir
func p_asakujaku(c: Node3D, t: Node3D) -> void:
	_gate_cost(c, 0.12)
	busy(c, 1.3)
	var d = fwd(c, t)
	var right = d.cross(Vector3.UP).normalized()
	for k in 18:
		after(k * 0.05, func():
			if not live(c):
				return
			anim(c, "jab" if k % 2 == 0 else "cross", 2.6)
			var off = right * randf_range(-2.2, 2.2) + Vector3.UP * randf_range(0.6, 2.6)
			var from = c.global_position + Vector3.UP * 1.3 + d * 0.6
			var b = MB.new()
			b.add("sphere", Vector3.ZERO, Vector3(0.5, 0.5, 0.8), Color(1, 0.6, 0.2))
			var mi = mesh_of(b, glow(Color(1, 0.55, 0.15), 0.85))
			var pr = shot(c, from, (d * 12.0 + off).normalized(), 46.0, mi, inf(c, "asakujaku", 0.18, {"element": "katon", "burn": 1.5, "knock": 2.0, "kind": "light"}), null, false, 0.6)
			Projectile.trail(pr, [Color(1, 0.7, 0.3, 0.9), Color(1, 0.3, 0.1, 0)], 0.35, 16, 0.3, FX.tex_smoke, true)
			if k % 4 == 0:
				Sfx.play("fire", from, 1.4, 0.4))
	FX.speed_lines(c.global_position + Vector3.UP, d)


## Gündüz Kaplanı: yedinci kapı; avuç ileri, kaplan başı biçiminde dev hava basıncı topu (her şeyi savurur)
func p_hirudora(c: Node3D, t: Node3D) -> void:
	_gate_cost(c, 0.15)
	busy(c, 1.0)
	anim(c, "push", 1.0)
	var d = fwd(c, t)
	after(0.35, func():
		if not live(c):
			return
		var from = c.global_position + Vector3.UP * 1.3 + d * 1.2
		var node = Node3D.new()
		var core = MeshInstance3D.new()
		core.mesh = VFX._sphere(1.6, 18, 10)
		core.material_override = glow(Color(0.85, 1.0, 0.9), 0.35)
		node.add_child(core)
		for sx in [-1.0, 1.0]:   # kaplan kulakları ve çene hatları (hava girdabı)
			var ear = MeshInstance3D.new()
			ear.mesh = VFX._sphere(0.6, 10, 6)
			ear.material_override = glow(Color(0.8, 1.0, 0.85), 0.3)
			ear.position = Vector3(sx * 1.2, 1.3, 0.2)
			node.add_child(ear)
		var pr = shot(c, from, d, 26.0, node, inf(c, "hirudora", 2.2, {"knock": 22.0, "launch": 6.0, "kind": "heavy", "hitstop": 0.1}), null, true, 1.4)
		Projectile.trail(pr, [Color(0.85, 1, 0.9, 0.6), Color(0.7, 0.9, 0.8, 0)], 1.4, 20, 0.5, FX.tex_smoke, false)
		shake(0.9)
		Sfx.play("wind", from, 0.5)
		Sfx.play("roar", from, 1.3, 0.5))


## Akşam Fili: sekizinci kapı; beş ardışık süpersonik yumruk, her biri öne uzanan hava şoku
func p_sekizo(c: Node3D, t: Node3D) -> void:
	_gate_cost(c, 0.2)
	busy(c, 2.0)
	var d = fwd(c, t)
	for k in 5:
		after(0.2 + k * 0.32, func():
			if not live(c):
				return
			anim(c, "cross", 2.0)
			var o = c.global_position + Vector3.UP * 0.4
			FX.ring(o + d * 2.0 + Vector3.UP, Color(0.8, 1, 0.8), 3.5 + k * 0.6, 0.3, false, d)
			VFX.puffs(o + d * 4.0 + Vector3.UP, {"amount": 30, "life": 0.5, "size": 1.0, "radius": 1.5, "vmin": 12, "vmax": 22, "dir": d, "spread": 15.0,
				"colors": [Color(0.9, 1, 0.9, 0.7), Color(0.7, 0.9, 0.7, 0)]})
			shake(0.5 + k * 0.1)
			Sfx.play("boom", o, 1.2 - k * 0.08, 0.6)
			Combat.hit_zone(c, o, d, 18.0 + k * 3.0, 14.0, 4.0, inf(c, "sekizo", 0.75, {"knock": 16.0, "launch": 3.0, "kind": "heavy", "hitstop": 0.05})))


## Gece Gayı: sekizinci kapının son tekmesi; kızıl ejderha biçimli buhar, uzayı büken tek hamlede hedefin içinden geç.
## Bedeli: canın %10'a iner, 12 sn bitkin (yavaş)
func p_yagai(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 30.0)
	busy(c, 1.8)
	anim(c, "crouch", 0.8)
	var a = FX.aura(c, Color(1, 0.25, 0.2), 2.4, Vector3(0, 0.9, 0), 0.0)
	Sfx.play("roar", c.global_position, 0.6)
	shake(1.0)
	after(0.9, func():
		if not live(c):
			return
		var d = fwd(c, tt)
		var start = c.global_position
		var dist = 26.0 if tt == null else c.global_position.distance_to(tt.global_position) + 6.0
		var end = gp(start + d * dist)
		# ejderha: başlangıçtan bitişe kıvrılan kızıl buhar şeridi
		for k in 14:
			var q = start.lerp(end, k / 13.0) + Vector3.UP * (1.2 + sin(k * 0.8) * 0.8) + d.cross(Vector3.UP) * cos(k * 0.6) * 1.2
			VFX.puffs(q, {"amount": 14, "life": 1.2, "size": 1.6 - k * 0.05, "radius": 0.8, "vmin": 0.5, "vmax": 2, "colors": [Color(1, 0.3, 0.2, 0.85), Color(0.7, 0.1, 0.1, 0)]})
		c.global_position = end
		anim(c, "dash", 1.4)
		Combat.hit_zone(c, start, d, dist, 10.0, 4.0, inf(c, "yagai", 6.0, {"knock": 30.0, "launch": 10.0, "kind": "heavy", "hitstop": 0.2}))
		VFX.slowmo(0.35, 0.6)
		shake(2.0)
		Sfx.play("boom", end, 0.4)
		if is_instance_valid(a):
			a.emitting = false
		if c is Player:
			c.hp = minf(c.hp, c.max_hp * 0.1)
			st(c, "slow", 12.0)
			Hud.msg("Gece Gayı'nın bedeli: bedenin tükendi.", Color(1, 0.4, 0.4)))


# ================================================================== Kâğıt Yolu
const PAPER := Color(0.96, 0.95, 0.98)
const PAPER_V := Color(0.62, 0.52, 0.85)


## Tek bir kâğıt yaprağı (dörtgen, hafif kıvrık)
func paper_sheet(s := 0.35) -> MeshInstance3D:
	var b = MB.new()
	b.add("box", Vector3.ZERO, Vector3(s, 0.006, s * 1.3), PAPER, Vector3(randf_range(-20, 20), randf() * 360.0, randf_range(-20, 20)))
	return mesh_of(b)








## Kâğıt Kanatlar: sırttan katmanlı kâğıt kanatlar açılır (kemiğe bağlı), 20 sn uçuş; kanat çırpınca kâğıt bıçaklar savrulur
func p_kami_tsubasa(c: Node3D, _t: Node3D) -> void:
	anim(c, "cast", 1.2)
	var m = c.get("model")
	var parts = []
	var wings = []
	if m and m.skel:
		var sk: Skeleton3D = m.skel
		var chest_b = "UpperChest" if sk.find_bone("UpperChest") >= 0 else "Chest"
		var p_ch: Vector3 = m._grest(sk.find_bone(chest_b)).origin
		for sx in [-1.0, 1.0]:
			var ba = m._attach(chest_b, Transform3D(Basis.IDENTITY, p_ch + Vector3(sx * 0.13, 0.0, -0.14)))   # kürek kemiği
			var b = MB.new()
			_paper_wing(b, sx)
			var wing = mesh_of(b)
			ba.get_child(0).add_child(wing)
			wing.scale = Vector3.ONE * 0.05
			wing.create_tween().tween_property(wing, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK)
			wing.set_meta("sx", sx)
			wings.append(wing)
			parts.append(ba)
	# kanat sırta bağlı ama gövde eğilse de dik durur (animedeki gibi kemer yukarıda, tüyler aşağı); yavaş çırpma
	every(20.0, 1.0 / 60.0, func(i, _k):
		if m == null or not is_instance_valid(m):
			return
		var tm = i / 60.0
		var fast = c is Player and Vector2(c.velocity.x, c.velocity.z).length() > 8.0
		var spd = 7.0 if fast else 4.0
		for w in wings:
			if not is_instance_valid(w):
				continue
			var sx = float(w.get_meta("sx"))
			var ph = sin(tm * spd)
			var sc: Vector3 = w.scale
			# çırpma: uçlar aşağı-yukarı (roll), kanat geriye katlanıp açılır (yaw), hızlıyken daha geride süzülür
			var roll = deg_to_rad(sx * (ph * 22.0 + 4.0))
			var yaw = deg_to_rad(-sx * ((30.0 if fast else 14.0) + cos(tm * spd) * 12.0))
			w.global_basis = m.global_basis.orthonormalized() * Basis.from_euler(Vector3(deg_to_rad(-8.0 + ph * 5.0), yaw, roll))
			w.scale = sc
		if i % 50 == 0 and live(c):
			Sfx.play("wind", c.global_position, 1.8, 0.25))
	Sfx.play("wind", c.global_position, 1.4)
	if c is Player and c.has_method("start_flight"):
		c.start_flight("kami", {"drain": 0.0, "speed": 20.0, "dur": 20.0})
		Buffs.add("kami_tsubasa", 20.0, {"speed": 1.15, "_name": "Kâğıt Kanatlar", "_desc": "uçuyorsun (Space/Ctrl); kanatlar kâğıt bıçak savurur"})
	every(20.0, 1.2, func(_i, _k):
		if not live(c):
			return
		var foes = enemies_near(c, c.global_position, 14.0)
		for k in 3:   # kanatlardan kopup savrulan kâğıtlar
			var sh = paper_sheet(0.12)
			get_tree().current_scene.add_child(sh)
			sh.global_position = c.global_position + Vector3(randf_range(-1.2, 1.2), randf_range(0.6, 2.4), randf_range(-0.6, 0.2))
			var tw = sh.create_tween()
			tw.tween_property(sh, "global_position", sh.global_position + Vector3(randf_range(-2, 2), randf_range(-2.5, -1), randf_range(-2, 2)), 1.4)
			tw.parallel().tween_property(sh, "rotation", Vector3(randf() * 6, randf() * 6, randf() * 6), 1.4)
			tw.tween_callback(sh.queue_free)
		if not foes.is_empty():
			var e = foes.pick_random()
			var b2 = MB.new()
			b2.add("box", Vector3.ZERO, Vector3(0.05, 0.005, 0.5), PAPER)
			shot(c, c.global_position + Vector3.UP * 1.4, (e.global_position + Vector3.UP - c.global_position - Vector3.UP * 1.4).normalized(), 40.0, mesh_of(b2), inf(c, "kami_tsubasa", 0.2, {"knock": 1.0, "kind": "light"}), null, false, 0.8), func():
		for pp in parts:
			if is_instance_valid(pp):
				pp.queue_free()
		if c is Player and is_instance_valid(c) and c.has_method("flight_source") and c.flight_source() == "kami":
			c.stop_flight())











# ================================================================== Kurbağa Bilgesi Yolu
const TOAD_OIL := Color(0.92, 0.75, 0.3)





## Yağ gölü: içindekiler yavaşlar; ateş vurursa alev gölüne döner
func _oil_pool(c: Node3D, at: Vector3, r: float, dur: float) -> void:
	at = gp(at)
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = r; cm.bottom_radius = r; cm.height = 0.05
	mi.mesh = cm
	mi.material_override = flat_mat(Color(0.75, 0.55, 0.15, 0.75))
	get_tree().current_scene.add_child(mi)
	mi.global_position = at + Vector3.UP * 0.04
	every(dur, 0.5, func(_i, _k):
		for e in enemies_near(c, at, r):
			st(e, "slow", 1.0), func():
		if is_instance_valid(mi):
			mi.queue_free())




















## Konan'ın melek kanadı: omuzdan başın üstüne kemer, oradan dizlere kadar sarkan tüy sütunları; her tüy küçük kâğıt tuğlalardan
func _paper_wing(b: MB, sx: float) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 77 if sx > 0 else 78
	var arm := func(u: float) -> Vector3:   # kemer (ikinci derece bezier): kök → yukarı → dış tepe
		var p0 = Vector2(0.0, 0.0); var p1 = Vector2(0.55, 0.12); var p2 = Vector2(1.0, 0.8)   # omuz hizasında dışa, uçta yukarı kemer
		var q = p0.lerp(p1, u).lerp(p1.lerp(p2, u), u)
		return Vector3(q.x * sx, q.y, -0.05 - q.x * 0.12)
	var cols = 15
	for ci in cols:
		var u = 0.12 + 0.88 * (ci + 0.5) / cols   # kökte (sırtta) tüy yok
		var top: Vector3 = arm.call(u)
		var L = 0.35 + 1.75 * pow(u, 1.3)                        # dışa doğru uzayan tüyler (dizlere iner)
		var dir = Vector3(sx * (0.1 + 0.3 * u), -1.0, -0.05).normalized()
		var n = int(L / 0.075)
		for k in n:
			var f = float(k) / maxf(1.0, n - 1)
			var w = 0.16 * (1.0 - 0.5 * pow(f, 2.0))           # uca doğru daralan tüy
			var q = top + dir * (k * 0.075) + Vector3(rng.randf_range(-0.012, 0.012), 0, (ci % 2) * -0.012)
			var col = PAPER.darkened(rng.randf_range(0.0, 0.1) + 0.06 * f)
			b.add("box", q, Vector3(w, 0.11, 0.008), col, Vector3(-4, 0, rad_to_deg(atan2(dir.x, -dir.y)) * -1.0 + rng.randf_range(-8, 8)))
	# kemer üzerindeki kalın üst kenar: çift sıra tuğla
	for k in 22:
		var u = 0.1 + 0.9 * k / 21.0
		var q: Vector3 = arm.call(u)
		var q2: Vector3 = arm.call(minf(1.0, u + 0.05))
		var ang = rad_to_deg(atan2(q2.y - q.y, (q2.x - q.x) * sx))
		for r in 2:
			b.add("box", q + Vector3(0, -0.06 * r, 0.006), Vector3(0.13, 0.09, 0.009), PAPER.darkened(0.03 * r + rng.randf_range(0, 0.05)), Vector3(-10, 0, ang * sx))


## Omuzda oturan yaşlı bilge kurbağa: yüksek yakalı cübbe, kulak diski, alın bandı; erkek: beyaz diken saç/kaş/keçi sakal + sırtta parşömen, dişi: kıvırcık mor saç, mor dudak (+Z öne bakar)
func _elder_toad(female: bool) -> MB:
	var skin = Color(0.48, 0.58, 0.3) if not female else Color(0.85, 0.86, 0.62)
	var robe = Color(0.5, 0.48, 0.45) if not female else Color(0.28, 0.2, 0.32)
	var robe_d = robe.darkened(0.25)
	var white = Color(0.95, 0.95, 0.93)
	var purple = Color(0.55, 0.32, 0.65)
	var b = MB.new()
	# gövde cübbenin içinde: yalnızca ayaklar dışarıda
	b.add("sphere", Vector3(0, 0.07, 0), Vector3(0.2, 0.15, 0.19), skin)
	for ex in [-1.0, 1.0]:
		b.add("sphere", Vector3(ex * 0.07, 0.012, 0.075), Vector3(0.045, 0.025, 0.06), skin)          # ön ayak parmakları
	b.add("sphere", Vector3(0, 0.08, -0.005), Vector3(0.235, 0.18, 0.225), robe, Vector3.ZERO, 12)    # cübbe gövdeyi sarar
	b.add("cyl", Vector3(0, 0.008, -0.005), Vector3(0.25, 0.016, 0.23), robe_d, Vector3.ZERO, 12)     # etek kenarı
	b.add("cyl", Vector3(0, 0.14, -0.005), Vector3(0.205, 0.05, 0.195), robe_d, Vector3.ZERO, 14)    # kalın yüksek yaka
	b.add("cyl", Vector3(0, 0.168, -0.005), Vector3(0.21, 0.012, 0.2), robe, Vector3.ZERO, 14)      # yaka kıvrımı
	b.add("sphere", Vector3(0, 0.17, -0.065), Vector3(0.15, 0.11, 0.07), robe_d)                      # sırtta kapüşon
	b.add("box", Vector3(0, 0.11, 0.1), Vector3(0.012, 0.09, 0.006), robe_d)                          # önde cübbe yarığı
	# baş
	b.add("sphere", Vector3(0, 0.17, 0.02), Vector3(0.18, 0.12, 0.16), skin)
	b.add("sphere", Vector3(0, 0.145, 0.07), Vector3(0.13, 0.05, 0.08), skin.darkened(0.05))         # ağız/çene
	for ex in [-1.0, 1.0]:
		b.add("sphere", Vector3(ex * 0.055, 0.215, 0.065), Vector3(0.055, 0.045, 0.045), skin)        # göz tümseği
		b.add("sphere", Vector3(ex * 0.058, 0.218, 0.085), Vector3(0.034, 0.03, 0.012), Color(0.92, 0.7, 0.2))
		b.add("box", Vector3(ex * 0.058, 0.218, 0.092), Vector3(0.024, 0.005, 0.003), Color(0.05, 0.05, 0.05))
		b.add("cyl", Vector3(ex * 0.088, 0.17, 0.01), Vector3(0.035, 0.008, 0.035), Color(0.7, 0.7, 0.66), Vector3(0, 0, 90), 10)   # kulak diski
		b.add("box", Vector3(ex * 0.092, 0.17, 0.01), Vector3(0.002, 0.004, 0.026), Color(0.35, 0.35, 0.33))
	b.add("cyl", Vector3(0, 0.2, 0.02), Vector3(0.185, 0.02, 0.165), Color(0.2, 0.24, 0.42), Vector3(-12, 0, 0), 16)   # alın bandı başı sarar
	b.add("box", Vector3(0, 0.208, 0.1), Vector3(0.045, 0.022, 0.004), Color(0.78, 0.8, 0.84), Vector3(-12, 0, 0))     # bant plakası
	b.add("box", Vector3(0, 0.208, 0.103), Vector3(0.024, 0.004, 0.002), Color(0.3, 0.3, 0.32), Vector3(-12, 0, 0))
	if not female:
		b.add("box", Vector3(0, 0.135, 0.11), Vector3(0.07, 0.004, 0.004), Color(0.15, 0.17, 0.1))   # düz, ciddi ağız
		for ex in [-1.0, 1.0]:
			for k in 3:   # diken kaşlar
				b.add("cone", Vector3(ex * (0.045 + k * 0.018), 0.238 + k * 0.004, 0.085), Vector3(0.016, 0.05, 0.01), white, Vector3(0, 0, -ex * (55 + k * 12)), 4)
		for k in 5:   # tepede beyaz diken saç
			b.add("cone", Vector3((k - 2) * 0.022, 0.27, 0.0 - abs(k - 2) * 0.01), Vector3(0.022, 0.06, 0.022), white, Vector3(-15, 0, (k - 2) * 22), 4)
		b.add("cone", Vector3(0, 0.11, 0.1), Vector3(0.035, 0.05, 0.015), white, Vector3(180, 0, 0), 4)   # keçi sakal
		b.add("cyl", Vector3(0.0, 0.13, -0.12), Vector3(0.035, 0.18, 0.035), Color(0.9, 0.82, 0.62), Vector3(0, 0, 70), 8)   # sırtta parşömen
		b.add("cyl", Vector3(0.0, 0.13, -0.12), Vector3(0.04, 0.03, 0.04), Color(0.6, 0.15, 0.12), Vector3(0, 0, 70), 8)
	else:
		b.add("box", Vector3(0, 0.138, 0.112), Vector3(0.1, 0.012, 0.006), purple, Vector3(0, 0, 0))   # geniş mor dudak (gülümser)
		for ex in [-1.0, 1.0]:
			b.add("box", Vector3(ex * 0.055, 0.143, 0.108), Vector3(0.025, 0.01, 0.006), purple, Vector3(0, 0, ex * 20))
		for k in 9:   # kıvırcık mor saç topları
			var a = PI * (k / 8.0)
			b.add("sphere", Vector3(cos(a) * 0.085, 0.24 + sin(a) * 0.045, -0.03), Vector3(0.05, 0.05, 0.05), purple)
		b.add("sphere", Vector3(0, 0.27, -0.02), Vector3(0.12, 0.06, 0.1), purple)
	return b


## Katlanmış kâğıt shuriken: 4 kanat, her kanat iki üçgen yüz (kat çizgisi gölgeli), ortada kare göbek
func _paper_star() -> MB:
	var b = MB.new()
	for k in 4:
		var a = k * 90.0
		var d = Vector3(cos(deg_to_rad(a)), 0, sin(deg_to_rad(a)))
		b.add("cone", d * 0.11, Vector3(0.09, 0.2, 0.006), PAPER, Vector3(90, 0, 0).rotated(Vector3.UP, 0) + Vector3(0, -a + 90, 0), 3)
		b.add("box", d * 0.1 + Vector3(0, 0.004, 0), Vector3(0.012, 0.004, 0.16), PAPER.darkened(0.2), Vector3(0, -a + 90, 0))   # kat çizgisi
	b.add("box", Vector3.ZERO, Vector3(0.08, 0.012, 0.08), PAPER.darkened(0.08), Vector3(0, 45, 0))
	return b


## Kâğıt Shuriken: elden yelpaze gibi açılan 5 katlanmış kâğıt yıldız; dönerek uçar, hedefe hafif yönelir, arkasında kâğıt kırpıntıları
func p_kami_shuriken(c: Node3D, t: Node3D) -> void:
	busy(c, 0.45)
	var tt = tg(c, t, 30.0)
	var d = fwd(c, t)
	if tt:
		d = (tt.global_position + Vector3.UP - c.global_position - Vector3.UP * 1.3).normalized()
	var from = hand_pos(c, true)
	Sfx.play("whoosh", from, 1.8, 0.5)
	for k in 5:
		after(k * 0.05, func():
			if not live(c):
				return
			var dir = d.rotated(Vector3.UP, deg_to_rad((k - 2) * 7.0))
			var pr = shot(c, from, dir, 38.0, mesh_of(_paper_star()), inf(c, "kami_shuriken", 0.35, {"knock": 1.5, "kind": "light", "bleed": 2.0}), tt, false, 1.4)
			pr.spin = Vector3(0, 28.0, 0)
			Projectile.trail(pr, [Color(1, 1, 1, 0.9), Color(0.85, 0.82, 0.95, 0)], 0.08, 10, 0.35, null, false))


# ================================================================== Akademi / genel teknikler (kendi koreografisi)
const LEAF := Color(0.45, 0.75, 0.3)


func _kick_pose(c: Node3D, dur: float) -> void:
	if c.get("model") and c.model.overlay:
		c.model.overlay.set_pose("kick", 1.0)
		after(dur, func():
			if is_instance_valid(c) and c.get("model") and c.model.overlay:
				c.model.overlay.set_pose("kick", 0.0))


func _leaves(at: Vector3, n: int, spd := 6.0) -> void:
	VFX.puffs(at, {"amount": n, "life": 0.9, "size": 0.18, "radius": 0.6, "vmin": spd * 0.5, "vmax": spd, "dir": Vector3.UP, "spread": 80.0, "add": false,
		"colors": [LEAF, LEAF.darkened(0.3), Color(0.6, 0.8, 0.35, 0)]})


## Atış yönü: hedef varsa göğsüne, yoksa nişangâha (Jutsu._aim)
func aim_at(c: Node3D, tt: Node3D, from: Vector3) -> Vector3:
	if tt and is_instance_valid(tt):
		return (tt.global_position + Vector3.UP * tt.height * 0.55 - from).normalized()
	return Jutsu._aim(c, tt)


func _face(c: Node3D, tt: Node3D) -> Vector3:
	var d = fwd(c, tt)
	if tt:
		d = tt.global_position - c.global_position
		d.y = 0
		d = d.normalized()
		if c is Player:
			c.combat.face_to(tt)
	return d








## Yaprak Kasırgası (Senpū): zıplayıp dönen yüksek tekme — çevresindeki herkesi savurur, yapraklar uçuşur
func p_konoha_senpu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.55)
	var tt = tg(c, t, 6.0)
	var d = _face(c, tt)
	_kick_pose(c, 0.45)
	if c is CharacterBody3D:
		c.velocity = d * (8.0 if tt else 3.0) + Vector3.UP * 4.0
	var ctr = c.global_position + Vector3.UP * 1.1
	for k in 8:
		after(k * 0.04, func():
			var a = k * TAU / 8.0
			VFX.puffs(ctr + Vector3(cos(a), 0, sin(a)) * 1.3, {"amount": 4, "life": 0.3, "size": 0.35, "radius": 0.1, "vmin": 1, "vmax": 2, "dir": Vector3.UP, "spread": 30.0,
				"colors": [Color(1, 1, 1, 0.7), Color(1, 1, 1, 0)]}))
	_leaves(c.global_position + Vector3.UP * 0.4, 30)
	Sfx.play("whoosh", ctr, 1.2, 0.6)
	after(0.15, func():
		if live(c):
			mhit(c, c.global_position + Vector3.UP * 1.1, 2.4, inf(c, "konoha_senpu", 1.1, {"knock": 12.0, "launch": 3.0, "kind": "heavy"})))


## Yaprak Kasırgası (Reppū): kayarak alçak süpürme tekmesi — ayağını alır, yere serer
func p_konoha_reppu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.6)
	var d = _face(c, tg(c, t, 7.0))
	anim(c, "slide", 1.6)
	if c is CharacterBody3D:
		c.velocity = d * 12.0
	_leaves(c.global_position + Vector3.UP * 0.2, 20, 4.0)
	after(0.2, func():
		if not live(c):
			return
		for e in mhit(c, c.global_position + d * 1.0 + Vector3.UP * 0.3, 1.6, inf(c, "konoha_reppu", 0.9, {"knock": 3.0, "kind": "heavy"})):
			st(e, "stun", 1.2)
			Combat.popup_text(e.global_position + Vector3.UP * 2.0, "Ayağı alındı!", LEAF))
	Sfx.play("whoosh", c.global_position, 1.0, 0.5)


## Dinamik Giriş: uçan çift ayak tekmesi — hedefe atılır, çarpınca uzağa savurur
func p_dainamikku_entori(c: Node3D, t: Node3D) -> void:
	var d = _face(c, tg(c, t, 14.0))
	busy(c, 0.6)
	_kick_pose(c, 0.55)
	if c is CharacterBody3D:
		c.velocity = d * 22.0 + Vector3.UP * 4.0
	var done := {"v": false}
	every(0.5, 1.0 / 30.0, func(_i, _k):
		if done["v"] or not live(c):
			return
		VFX.puffs(c.global_position + Vector3.UP * 0.8, {"amount": 2, "life": 0.25, "size": 0.4, "radius": 0.2, "vmin": 0, "vmax": 1, "dir": Vector3.UP, "spread": 20.0,
			"colors": [Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)]})
		var hs = mhit(c, c.global_position + Vector3.UP * 0.9 + d * 0.8, 1.2, inf(c, "dainamikku_entori", 1.4, {"knock": 22.0, "launch": 4.0, "kind": "heavy", "dir": d}))
		if not hs.is_empty():
			done["v"] = true
			shake(0.4)
			_mfx(c, hs[0].global_position + Vector3.UP, Color(1, 0.9, 0.7), 1.2)
			if c is CharacterBody3D:
				c.velocity = -d * 5.0 + Vector3.UP * 5.0)





## Bin Yıllık Ölüm: hedefin arkasında belirip iki parmakla dürter — hedef havaya fırlar
func p_sennen_goroshi(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 10.0)
	if tt == null:
		if c is Player:
			Hud.msg("Arkasına geçecek hedef yok", Color(1, 0.7, 0.5))
		return
	busy(c, 0.8)
	FX.smoke_puff(c.global_position + Vector3.UP, 0.6, 8)
	var away = (tt.global_position - c.global_position)
	away.y = 0
	c.global_position = gp(tt.global_position + away.normalized() * 1.1)
	if c is Player:
		c.combat.face_to(tt)
	anim(c, "crouch", 1.5)
	Combat.popup_text(c.global_position + Vector3.UP * 2.2, "Bin Yıllık Ölüm!!", Color(1, 0.6, 0.7))
	after(0.45, func():
		if not live(tt) or not live(c):
			return
		anim(c, "jab", 1.6)
		tt.take_hit(inf(c, "sennen_goroshi", 0.8, {"knock": 2.0, "launch": 14.0, "kind": "heavy"}))
		st(tt, "stun", 1.5)
		VFX.puffs(tt.global_position + Vector3.UP * 0.9, {"amount": 20, "life": 0.5, "size": 0.3, "radius": 0.2, "vmin": 3, "vmax": 7, "dir": Vector3.UP, "spread": 50.0,
			"colors": [Color(1, 0.7, 0.8, 0.9), Color(1, 0.9, 0.9, 0)]})
		Sfx.play("punch", tt.global_position, 1.4))





## PSTYLE: doton_renga_no_jutsu=ground doton_sazareishi=palm doton_shinju_zanshu_no_jutsu=ground kasumi_jusha_no_jutsu=sense oboro_bunshin_no_jutsu=clone doton_tobi_tsubute=ground doton_dosekiryu=ground doton_retsudo_tensho=ground futon_reppusho=palm futon_kazekiri_no_jutsu=palm katon_endan=breath
# ------------------------------------------------------------------ Grup 2: düşük seviye toprak / rüzgâr / ateş / klon
const EARTH := Color(0.55, 0.42, 0.3)


func _rock(s: float, col := EARTH) -> MeshInstance3D:
	var b = MB.new()
	b.add("boulder", Vector3.ZERO, Vector3(s, s * 0.8, s), col, Vector3(randf() * 360, randf() * 360, 0), 3)
	return mesh_of(b)

































## PSTYLE: bubble_clone_technique=clone bubitorappu=ground chakura_kontororu_baku=palm earth_release_rock_shelter=ground fujinheki=two_palm futon_fujin_no_jutsu=breath futon_toppa=breath genjutsu_shibari=sense hayanie=rush jouro_senbon=throw juha_sho=spin kamaitachi_no_jutsu=spin konoha_daisenpu=rush konoha_otoshi=rush kaeru_kaeru_no_jutsu=palm

# ------------------------------------------------------------------ Grup 3: rüzgâr / genjutsu / taijutsu / tuzak
const WIND := Color(0.85, 1.0, 0.95)


























## Erken Kurban: hedefi yakalar, havaya kaldırıp sırtüstü yere çakar
func p_hayanie(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 4.0)
	busy(c, 0.8)
	_face(c, tt)
	anim(c, "push", 1.4)
	if tt == null:
		return
	st(tt, "stun", 1.2)
	var y0 = tt.global_position
	var tw = tt.create_tween()
	tw.tween_property(tt, "global_position", y0 + Vector3.UP * 2.2 + c.face_dir() * 0.5, 0.25)
	tw.tween_property(tt, "global_position", gp(y0 + c.face_dir() * 1.5), 0.12)
	tw.tween_callback(func():
		if live(tt):
			tt.take_hit(inf(c, "hayanie", 1.6, {"knock": 2.0, "kind": "heavy"}))
			_mfx(c, tt.global_position, Color(0.9, 0.8, 0.6), 1.3)
			VFX.debris(tt.global_position, EARTH, 12, 5.0)
			shake(0.5)
			Sfx.play("hit_heavy", tt.global_position, 1.0))











## Büyük Yaprak Kasırgası: art arda üç dönen tekme, her biri daha yüksek
func p_konoha_daisenpu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	var d = _face(c, tt)
	busy(c, 1.0)
	for k in 3:
		after(k * 0.28, func():
			if not live(c):
				return
			_kick_pose(c, 0.22)
			if c is CharacterBody3D:
				c.velocity = d * 5.0 + Vector3.UP * (3.0 + k * 1.5)
			_leaves(c.global_position + Vector3.UP * 0.6, 18)
			mhit(c, c.global_position + Vector3.UP * (1.0 + k * 0.3) + d * 0.8, 2.2, inf(c, "konoha_daisenpu", 0.6, {"knock": 4.0 + k * 6.0, "launch": 2.0 + k * 2.0, "kind": "heavy"}))
			Sfx.play("punch", c.global_position, 1.2 - k * 0.1))


## Yaprak Düşüşü: havaya sıçrayıp yukarıdan topukla iner — yer çatlar
func p_konoha_otoshi(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 7.0)
	var d = _face(c, tt)
	busy(c, 0.8)
	if c is CharacterBody3D:
		c.velocity = d * 4.0 + Vector3.UP * 9.0
	_kick_pose(c, 0.7)
	after(0.45, func():
		if not live(c):
			return
		if c is CharacterBody3D:
			c.velocity = d * 3.0 + Vector3.DOWN * 22.0
		after(0.15, func():
			var at = gp(c.global_position + d * 0.8)
			_mfx(c, at + Vector3.UP * 0.3, Color(1, 0.9, 0.7), 1.4)
			FX.ring(at + Vector3.UP * 0.05, EARTH, 4.0, 0.4)
			VFX.debris(at, EARTH, 16, 6.0)
			shake(0.6)
			for e in mhit(c, at + Vector3.UP, 2.4, inf(c, "konoha_otoshi", 1.5, {"knock": 4.0, "kind": "heavy"})):
				st(e, "stun", 1.0)
			Sfx.play("hit_heavy", at, 0.9)))



## PSTYLE: futon_hanachiri_mai=spin genjutsu_suzune_bunshin=sense kage_buyo=rush karasu_bunshin_no_jutsu=clone kawazu_kumite=power kawazu_tataki=rush konoha_shofu=rush kumo_ryu_omotegiri=rush kumo_ryu_uragiri=rush kumo_shibari=palm kumo_soka=palm kumogakure_taijutsu_okami_ringu=spin kyomeisen=palm mizuame_teppo=breath nekozume=rush okasho=rush raigeki=rush raigyaku_suihei_choppu=rush raikyu=palm raiton_ikazuchi_unagi=palm raiton_raiju_tsuiga=palm rakanken=rush shikomishindan=throw shishi_rendan=rush

# ------------------------------------------------------------------ Grup 4: rüzgâr dansı / ses / genjutsu / senjutsu / ağ / Bulut kılıcı / şimşek / ağır taijutsu
const RAI := Color(0.65, 0.85, 1.0)
const WEB := Color(0.92, 0.92, 0.88)
const SAGE := Color(1.0, 0.65, 0.2)


func _bolt(a: Vector3, b: Vector3, col := RAI, w := 0.12) -> void:
	VFX.bolt(a, b, col, w, 0.25, 0)


func _jump_at(c: Node3D, tt: Node3D, up: float, fwd_v: float) -> Vector3:
	var d = _face(c, tt)
	if c is CharacterBody3D:
		c.velocity = d * fwd_v + Vector3.UP * up
	return d








## Dans Eden Yaprağın Gölgesi: hedefi tekmeyle havaya fırlatır, gölgesi gibi peşinden sıçrar ve tepede vurur
func p_kage_buyo(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 5.0)
	busy(c, 1.0)
	_face(c, tt)
	_kick_pose(c, 0.25)
	if tt == null:
		return
	tt.take_hit(inf(c, "kage_buyo", 0.4, {"knock": 0.0, "launch": 13.0, "kind": "heavy"}))
	_leaves(tt.global_position, 20)
	after(0.3, func():
		if not live(c) or not live(tt):
			return
		c.global_position = tt.global_position - c.face_dir() * 0.8 - Vector3.UP * 0.6
		if c is CharacterBody3D:
			c.velocity = Vector3.UP * 3.0
		Combat.popup_text(c.global_position + Vector3.UP * 2.2, "Kage Buyō!", LEAF)
		after(0.2, func():
			if live(tt):
				anim(c, "hook", 1.6)
				tt.take_hit(inf(c, "kage_buyo", 0.9, {"knock": 8.0, "launch": -8.0, "kind": "heavy"}))
				_mfx(c, tt.global_position + Vector3.UP, Color(1, 0.9, 0.7), 1.0)))








## Kurbağa Vuruşu: doğa enerjili tek ağır yumruk — dokunmadan önce aura çarpar, uzağa uçurur
func p_kawazu_tataki(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	_jump_at(c, tt, 0.0, 10.0 if tt else 3.0)
	busy(c, 0.6)
	after(0.2, func():
		if not live(c):
			return
		anim(c, "cross", 1.4)
		var at = c.global_position + c.face_dir() * 1.4 + Vector3.UP * 1.1
		_mfx(c, at, SAGE, 1.6)
		FX.ring(at, SAGE, 3.0, 0.4, false, c.face_dir())
		shake(0.5)
		mhit(c, at, 2.0, inf(c, "kawazu_tataki", 1.8, {"knock": 24.0, "launch": 4.0, "kind": "heavy"}))
		Sfx.play("hit_heavy", at, 0.8))


## Yükselen Yaprak Rüzgârı: çömelip yukarı tekme — hedef dik havaya fırlar
func p_konoha_shofu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 4.0)
	_jump_at(c, tt, 0.0, 6.0 if tt else 0.0)
	busy(c, 0.5)
	anim(c, "crouch", 2.0)
	after(0.18, func():
		if not live(c):
			return
		_kick_pose(c, 0.3)
		_leaves(c.global_position + Vector3.UP * 0.4, 20, 8.0)
		mhit(c, c.global_position + c.face_dir() * 0.8 + Vector3.UP * 0.8, 1.6, inf(c, "konoha_shofu", 1.0, {"knock": 1.0, "launch": 16.0, "kind": "heavy"}))
		Sfx.play("punch", c.global_position, 1.1))


## Bulut Stili Ön Kesik: tek adımda öne atılıp çapraz kılıç darbesi (kılıç yoksa çakra bıçağı)
func p_kumo_ryu_omotegiri(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 9.0)
	var d = _jump_at(c, tt, 0.0, 26.0 if tt else 12.0)
	busy(c, 0.5)
	anim(c, "slash_a", 1.8)
	after(0.12, func():
		if not live(c):
			return
		if c is CharacterBody3D:
			c.velocity = d * 2.0
		_arc_cut(c.global_position + Vector3.UP * 1.1 + d * 1.0, d, -40.0, 40.0, Color(0.85, 0.9, 1.0))
		mhit(c, c.global_position + Vector3.UP * 1.0 + d * 1.2, 1.8, inf(c, "kumo_ryu_omotegiri", 1.2, {"knock": 8.0, "kind": "heavy", "bleed": 3.0}))
		Sfx.play("clink", c.global_position, 1.3))


## Bulut Stili Ters Kesik: ters tutuşla dönüp sırttan gelen aldatıcı kesik — rakip savunamaz (sersemler)
func p_kumo_ryu_uragiri(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	var d = _jump_at(c, tt, 0.0, 10.0 if tt else 4.0)
	busy(c, 0.6)
	anim(c, "slash_c", 1.7)
	after(0.2, func():
		if not live(c):
			return
		_arc_cut(c.global_position + Vector3.UP * 0.9 + d * 0.9, d, 160.0, 20.0, Color(0.9, 0.85, 1.0))
		for e in mhit(c, c.global_position + Vector3.UP + d * 1.1, 1.8, inf(c, "kumo_ryu_uragiri", 1.1, {"knock": 6.0, "kind": "heavy", "bleed": 3.0})):
			st(e, "stun", 0.8)
		Sfx.play("clink", c.global_position, 1.1))


## Kılıç yayı izi: yatay yay boyunca parlak ince şeritler (a0..a1 derece)
func _arc_cut(at: Vector3, d: Vector3, a0: float, a1: float, col: Color, r := 1.4) -> void:
	for k in 9:
		var a = deg_to_rad(lerpf(a0, a1, k / 8.0))
		var q = at + d.rotated(Vector3.UP, a) * r
		var seg = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.35, 0.03, 0.05)
		seg.mesh = bm
		seg.material_override = glow(col, 0.9)
		get_tree().current_scene.add_child(seg)
		seg.global_position = q
		seg.rotation.y = atan2(d.rotated(Vector3.UP, a).x, d.rotated(Vector3.UP, a).z) + PI * 0.5
		var tw = seg.create_tween()
		tw.tween_interval(k * 0.012)
		tw.tween_property(seg, "scale", Vector3(0.01, 1, 1), 0.25)
		tw.tween_callback(seg.queue_free)








## Kurt Halkası: kılıçla kendi etrafında tam tur dönerek daire kesik — her yandaki düşmana
func p_kumogakure_taijutsu_okami_ringu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.7)
	anim(c, "slash_b", 1.4)
	var at = c.global_position + Vector3.UP * 1.0
	_arc_cut(at, c.face_dir(), 0.0, 360.0, Color(0.85, 0.9, 1.0), 2.4)
	_arc_cut(at + Vector3.UP * 0.3, c.face_dir(), 20.0, 380.0, Color(0.7, 0.85, 1.0), 2.8)
	after(0.15, func():
		mhit(c, at, 3.2, inf(c, "kumogakure_taijutsu_okami_ringu", 1.2, {"knock": 12.0, "kind": "heavy", "bleed": 3.0})))
	Sfx.play("clink", at, 1.0)








## Kedi Pençesi: çakralı pençelerle çapraz üçlü çizik
func p_nekozume(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	var d = _jump_at(c, tt, 2.0, 12.0 if tt else 4.0)
	busy(c, 0.6)
	for k in 3:
		after(0.1 + k * 0.1, func():
			if not live(c):
				return
			anim(c, "hook" if k % 2 == 0 else "cross", 2.0)
			var at = c.global_position + Vector3.UP * 1.1 + d * 1.0
			for j in 3:
				var cut = MeshInstance3D.new()
				var bm = BoxMesh.new()
				bm.size = Vector3(0.04, 1.0, 0.04)
				cut.mesh = bm
				cut.material_override = glow(Color(0.7, 0.9, 1.0), 0.9)
				get_tree().current_scene.add_child(cut)
				cut.global_position = at + d.cross(Vector3.UP) * (j - 1) * 0.18
				cut.rotation = Vector3(0, atan2(d.x, d.z), deg_to_rad(35.0 * (1 if k % 2 == 0 else -1)))
				cut.create_tween().tween_property(cut, "scale", Vector3(1, 0.01, 1), 0.25).finished.connect(cut.queue_free)
			mhit(c, at, 1.6, inf(c, "nekozume", 0.4, {"knock": 3.0, "kind": "light", "bleed": 2.0})))
	Sfx.play("whoosh", c.global_position, 1.5)




















## Rakan Yumruğu: ağır, dalga gibi art arda dört yumruk — her biri ileri iter
func p_rakanken(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 5.0)
	var d = _face(c, tt)
	busy(c, 1.0)
	for k in 4:
		after(k * 0.2, func():
			if not live(c):
				return
			anim(c, "jab" if k % 2 == 0 else "cross", 1.6)
			if c is CharacterBody3D:
				c.velocity = d * 5.0
			var at = c.global_position + Vector3.UP * 1.1 + d * 1.2
			_mfx(c, at, Color(1, 0.85, 0.6), 0.8 + k * 0.2)
			mhit(c, at, 1.6, inf(c, "rakanken", 0.5 + k * 0.15, {"knock": 3.0 + k * 4.0, "kind": "heavy"}))
			Sfx.play("punch", at, 1.0 - k * 0.08))





## Aslan Kombosu: tekmeyle havaya atar, gölge gibi arkasından sıçrar, art arda tekmeler ve havadan yere çakar
func p_shishi_rendan(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 5.0)
	busy(c, 1.6)
	_face(c, tt)
	_kick_pose(c, 0.25)
	if tt == null:
		return
	tt.take_hit(inf(c, "shishi_rendan", 0.4, {"knock": 0.0, "launch": 14.0, "kind": "heavy"}))
	after(0.3, func():
		if not live(c) or not live(tt):
			return
		c.global_position = tt.global_position - c.face_dir() * 0.8 - Vector3.UP * 0.4
		for k in 3:
			after(k * 0.12, func():
				if live(tt):
					_kick_pose(c, 0.1)
					tt.take_hit(inf(c, "shishi_rendan", 0.35, {"knock": 0.0, "launch": 2.0, "kind": "light"}))
					_mfx(c, tt.global_position + Vector3.UP, Color(1, 0.9, 0.7), 0.7))
		after(0.45, func():
			if live(tt):
				anim(c, "hook", 1.4)
				tt.take_hit(inf(c, "shishi_rendan", 1.4, {"knock": 4.0, "launch": -22.0, "kind": "heavy"}))
				Combat.popup_text(tt.global_position + Vector3.UP * 2.0, "Shishi Rendan!", Color(1, 0.6, 0.3))
				after(0.3, func():
					if live(tt):
						_mfx(c, tt.global_position, Color(1, 0.85, 0.6), 1.6)
						VFX.debris(tt.global_position, EARTH, 18, 7.0)
						shake(0.6)
						Sfx.play("hit_heavy", tt.global_position, 0.8))))
## PSTYLE: gofu_kekkai=seal mizu_bunshin_no_jutsu=clone nan_no_kaizo=power narikawari_no_jutsu=clone sanzengarasu_no_jutsu=sense sly_mind_affect_technique=sense sosai_no_ne=palm soshujin=throw suiken=rush suiton_homatsu_rappa=breath suiton_kokuu_no_jutsu=breath suiton_mizu_shibari=palm suiton_mizu_shuriken=throw suiton_mizuame_nabara=breath suiton_mizurappa=breath suiton_suiben=palm suiton_suidan_no_jutsu=breath suiton_suisandan=breath suiton_takitsubo_no_jutsu=ground suiton_teppodama=breath tsukikage=rush tsutenkyaku=rush uchi_naru_sakura=power water_release_wild_water_wave=breath zankukyokuha=two_palm zessenbaku=palm zessenzan=palm

# ------------------------------------------------------------------ Grup 5: su / mühür / ses / genjutsu / kurbağa dili / ağır taijutsu
const WATER := Color(0.35, 0.65, 1.0)


func _water_mat(a := 0.75) -> Material:
	return glow(Color(0.45, 0.75, 1.0), a)


func _splash(at: Vector3, s := 1.0) -> void:
	VFX.puffs(at, {"amount": int(30 * s), "life": 0.6, "size": 0.35 * s, "radius": 0.4 * s, "vmin": 3 * s, "vmax": 8 * s, "dir": Vector3.UP, "spread": 70.0, "add": false,
		"gravity": Vector3(0, -12, 0), "colors": [Color(0.75, 0.9, 1.0, 0.9), Color(0.5, 0.75, 1.0, 0)]})


func _mouth_pos(c: Node3D) -> Vector3:
	return c.global_position + Vector3.UP * 1.55 + c.face_dir() * 0.4


## Su küresi mermisi (ortak): ağızdan, çarpınca sıçrar
func _water_shot(c: Node3D, id: String, tt: Node3D, from: Vector3, s: float, speed: float, mul: float, extra := {}) -> Projectile:
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(s, s, s * 1.3), WATER)
	var info = {"knock": 6.0 * s, "kind": "heavy", "element": "suiton"}
	info.merge(extra, true)
	var pr = shot(c, from, aim_at(c, tt, from), speed, mesh_of(b, _water_mat()), inf(c, id, mul, info), null, false, 1.4, func(p, _h):
		_splash(p, s * 1.4))
	Projectile.trail(pr, [Color(0.75, 0.9, 1.0, 0.7), Color(0.5, 0.75, 1.0, 0)], s * 0.5, 18, 0.35, FX.tex_smoke, false)
	return pr





## Su Klonu: ayağının dibindeki sudan bir kopya yükselir; vurulunca su olup sıçrar
func p_mizu_bunshin_no_jutsu(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.5)
	var at = c.global_position + c.face_dir().cross(Vector3.UP) * 2.2
	_splash(at, 1.5)
	decoy(c, at, 9.0, func(pos):
		_splash(pos + Vector3.UP, 2.0))
	Sfx.play("water", at, 1.1)




















## Sarhoş Yumruk: sendeleyerek öngörülemez açılardan beş vuruş
func p_suiken(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	var d = _face(c, tt)
	busy(c, 1.2)
	for k in 5:
		after(k * 0.2, func():
			if not live(c):
				return
			var wob = d.rotated(Vector3.UP, randf_range(-0.8, 0.8))
			if c is CharacterBody3D:
				c.velocity = wob * 6.0 + Vector3.UP * (2.0 if k == 3 else 0.0)
			anim(c, ["jab", "hook", "cross", "slide", "hook"][k], 1.7)
			var at = c.global_position + Vector3.UP * (0.5 if k == 3 else 1.1) + wob * 1.1
			for e in mhit(c, at, 1.6, inf(c, "suiken", 0.45, {"knock": 4.0, "kind": "heavy"})):
				_mfx(c, e.global_position + Vector3.UP, Color(1, 0.85, 0.6), 0.8)
			Sfx.play("punch", at, 1.0 + randf() * 0.3))




















## Su Kırbacı: elde oluşan su kamçısı geniş yay çizer
func p_suiton_suiben(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 9.0)
	var d = _face(c, tt)
	busy(c, 0.6)
	anim(c, "slash_b", 1.4)
	for k in 10:
		after(k * 0.025, func():
			var a = deg_to_rad(-70.0 + k * 15.0)
			var q = c.global_position + Vector3.UP * 1.1 + d.rotated(Vector3.UP, a) * (1.0 + k * 0.5)
			_splash(q, 0.5))
	Combat.hit_zone(c, c.global_position, d, 7.0, 70.0, 2.5, inf(c, "suiton_suiben", 0.9, {"knock": 9.0, "kind": "heavy", "element": "suiton", "bleed": 1.0}))
	Sfx.play("whoosh", c.global_position, 1.2)














## Ay Gölgesi: kılıç ay hilali çizer, ardından solgun ay ışığı izi kalır
func p_tsukikage(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 8.0)
	var d = _jump_at(c, tt, 3.0, 14.0 if tt else 5.0)
	busy(c, 0.6)
	anim(c, "slash_c", 1.6)
	after(0.2, func():
		if not live(c):
			return
		var at = c.global_position + Vector3.UP * 1.3 + d * 0.8
		_arc_cut(at, d, -100.0, 100.0, Color(0.85, 0.9, 1.0), 2.0)
		_arc_cut(at + Vector3.UP * 0.15, d, -90.0, 90.0, Color(0.95, 0.97, 1.0), 1.8)
		mhit(c, at + d * 0.8, 2.2, inf(c, "tsukikage", 1.4, {"knock": 9.0, "kind": "heavy", "bleed": 3.0}))
		Sfx.play("clink", at, 0.9))


## Göğü Delen Topuk: havaya sıçrayıp topukla iner, yer patlar
func p_tsutenkyaku(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 8.0)
	var d = _jump_at(c, tt, 10.0, 6.0 if tt else 1.0)
	busy(c, 1.0)
	_kick_pose(c, 0.9)
	after(0.5, func():
		if not live(c):
			return
		if c is CharacterBody3D:
			c.velocity = Vector3.DOWN * 25.0
		after(0.12, func():
			var at = gp(c.global_position + d * 0.6)
			FX.impact(at + Vector3.UP * 0.3, Color(1, 0.9, 0.7), 2.0)
			for r in [3.0, 5.5, 8.0]:
				FX.ring(at + Vector3.UP * 0.05, EARTH, r, 0.5)
			VFX.debris(at, EARTH, 30, 10.0)
			shake(0.9)
			mhit(c, at + Vector3.UP, 5.0, inf(c, "tsutenkyaku", 1.9, {"knock": 14.0, "launch": 8.0, "kind": "heavy"}))
			Sfx.play("boom", at, 0.9)))

















# ================================================================== ORTAK DETAYLI EFEKT KATMANI (VFX kütüphanesi: shader çekirdek + iz + toplanma + çarpma + kalıcı iz)
## Element mermisi: elde/ağızda çakra toplanır, shader'lı element çekirdeği (alev/su/rüzgâr/şimşek) element iziyle uçar,
## çarpınca elemente özel büyük çarpma (şok dalgası, yıldız, patlama/sıçrama/arklar/toz, çatlak, yerde kalan iz)
func eshot(c: Node3D, id: String, el: String, col: Color, tt: Node3D, from: Vector3, size: float, speed: float, mul: float, extra := {}, impact_s := 1.0, delay := 0.16) -> void:
	VFX.gather(from, col, 0.8 + size * 0.4)
	after(delay, func():
		if not live(c):
			return
		var core = VFX.element_core(el, col, size)
		var info = {"knock": 8.0 * impact_s, "kind": "heavy", "element": el, "hitstop": 0.05}
		info.merge(extra, true)
		var pr = shot(c, from, aim_at(c, tt, from), speed, core, inf(c, id, mul, info), null, false, 1.6, func(p, _h):
			impact_fx(el, col, p, impact_s))
		pr.radius = 0.35 + size * 0.4
		_etrail(pr, el, col, size))


func _etrail(pr: Projectile, el: String, col: Color, size: float) -> void:
	VFX.element_trail(pr, el, col, size * 0.9)
	match el:
		"katon":
			Projectile.trail(pr, [Color(1, 0.85, 0.35, 0.9), Color(1, 0.4, 0.05, 0.6), Color(0.25, 0.12, 0.08, 0)], size * 0.8, 30, 0.5, FX.tex_smoke, false)
		"suiton":
			Projectile.trail(pr, [Color(0.97, 0.99, 1, 1), Color(0.55, 0.82, 1, 0.9), Color(0.15, 0.4, 0.95, 0)], size * 0.9, 34, 0.5, FX.tex_smoke, false)
		"fuuton":
			Projectile.trail(pr, [Color(1, 1, 1, 0.6), Color(0.8, 1, 0.92, 0.35), Color(0.7, 0.95, 0.85, 0)], size * 1.0, 24, 0.4, FX.tex_smoke, false)
		"raiton":
			Projectile.trail(pr, [Color(1, 1, 1, 1), col.lightened(0.4), Color(col.r, col.g, col.b, 0)], size * 0.4, 30, 0.3, null, true)


## Elemente özel çarpma (s: ölçek)
func impact_fx(el: String, col: Color, at: Vector3, s := 1.0) -> void:
	var g = Vector3(at.x, Game.ground_height(at.x, at.z), at.z)
	var near_ground = at.y - g.y < 2.5
	VFX.star(at, col.lightened(0.4), 2.2 * s, 0.18)
	VFX.shockwave(at, col, 5.0 * s, 0.4, false, Vector3.UP)
	match el:
		"katon", "bakuton", "yoton":
			VFX.explosion(at, 1.1 * s, col)
			VFX.embers(at, col, int(30 * s), 12.0 * s)
			if near_ground:
				VFX.cracks(g, 3.0 * s, Color(0.08, 0.04, 0.02, 0.9), 6.0)
		"suiton", "hyoton":
			VFX.splash(at, 2.6 * s)
			VFX.smoke_ring(g + Vector3.UP * 0.1, 3.5 * s, Color(0.75, 0.88, 1.0))
		"fuuton":
			VFX.shockwave(at, Color(0.9, 1, 0.95), 7.0 * s, 0.3, true)
			VFX.smoke_ring(g + Vector3.UP * 0.1, 4.0 * s, Color(0.85, 0.8, 0.7))
			VFX.debris(g, Color(0.7, 0.65, 0.55), int(10 * s), 8.0 * s, 0.25)
		"raiton":
			for k in int(8 * s):
				VFX.bolt(at, at + Vector3(randf_range(-3, 3), randf_range(-1, 3), randf_range(-3, 3)) * s, col, 0.12 * s, 0.3, 2)
			if near_ground:
				VFX.cracks(g, 2.0 * s, Color(0.1, 0.12, 0.2, 0.8), 4.0)
		"doton":
			VFX.debris(g, EARTH, int(24 * s), 10.0 * s, 0.6)
			VFX.cracks(g, 3.5 * s)
			VFX.smoke_ring(g + Vector3.UP * 0.1, 4.0 * s, Color(0.55, 0.45, 0.35))
		_:
			FX.impact(at, col, 1.2 * s)
	if near_ground and el in ["katon", "suiton", "doton", "raiton", "yoton", "hyoton"]:
		VFX.linger(at, el, col, 1.3 * s, 3.0)
	shake(0.25 + 0.25 * s)


## Ağır yakın dövüş darbesi: yıldız patlaması, yönlü şok halkası, toz, kıvılcım, hız çizgileri
func melee_fx(c: Node3D, at: Vector3, col: Color, s := 1.0, ground := false) -> void:
	VFX.star(at, col.lightened(0.5), 2.0 * s, 0.15)
	VFX.shockwave(at, col, 3.5 * s, 0.3, false, c.face_dir())
	FX.impact(at, col, 1.0 * s)
	FX.burst(at, {"amount": int(16 * s), "life": 0.35, "tex": FX.tex_spark, "add": true, "size": 0.3 * s, "radius": 0.3, "vmin": 6.0, "vmax": 14.0, "dir": c.face_dir(), "spread": 60.0,
		"colors": [Color(1, 1, 1, 1), col, Color(col.r, col.g, col.b, 0)]})
	if ground:
		var g = gp(at)
		VFX.cracks(g, 3.0 * s)
		VFX.debris(g, EARTH, int(16 * s), 9.0 * s, 0.5)
		VFX.smoke_ring(g + Vector3.UP * 0.1, 3.5 * s, Color(0.6, 0.52, 0.42))
	if s >= 1.3 and c is Player:
		VFX.screen_lines(0.3, 0.8)
	shake(0.2 + 0.3 * s)


## Alev Mermisi: ağızda alev toplanır, katmanlı dönen alev küresi uçar; çarpınca patlama, kor, yerde yanan alev dilleri
func p_katon_endan(c: Node3D, t: Node3D) -> void:
	busy(c, 0.55)
	var tt = tg(c, t, 26.0)
	for k in 3:
		after(k * 0.14, func():
			if live(c):
				eshot(c, "katon_endan", "katon", Color(1.0, 0.5, 0.1), tt, _mouth_pos(c) + c.face_dir() * 0.5, 0.9 - k * 0.15, 30.0, 0.35, {"burn": 2.5}, 1.0 - k * 0.2, 0.1))
	Sfx.play("fire", c.global_position, 1.2)


## Kasırga Avuç: avuçta dönen hava küresi (kırılan kabuk + iç spiral) — çarpınca yatay şok halkası, toz halkası
func p_futon_reppusho(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	anim(c, "push", 1.6)
	eshot(c, "futon_reppusho", "fuuton", Color(0.8, 1.0, 0.92), tg(c, t, 24.0), hand_pos(c, true), 1.3, 30.0, 0.8, {"knock": 18.0, "launch": 4.0}, 1.3)
	FX.speed_lines(c.global_position + Vector3.UP * 1.3, c.face_dir())
	Sfx.play("wind", c.global_position, 1.3)


## Dev Su Mermisi: ağızda su toplanır, akan su dokulu dev küre; çarpınca dev sıçrama, dalga halkası, yerde su birikintisi
func p_suiton_teppodama(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	eshot(c, "suiton_teppodama", "suiton", Color(0.3, 0.6, 1.0), tg(c, t, 26.0), _mouth_pos(c) + c.face_dir() * 0.9, 2.4, 24.0, 1.6, {"knock": 20.0, "launch": 3.0}, 1.8, 0.3)
	VFX.splash(gp(c.global_position + c.face_dir()) , 1.2)
	shake(0.3)
	Sfx.play("water", c.global_position, 0.6)


## Şimşek Küresi: avuçta çatırdayan parlak çekirdek ve titreyen kalın arklar; çarpınca dallanan şimşekler, yanık iz
func p_raikyu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	var from = hand_pos(c, true)
	for k in 5:
		VFX.bolt(from, from + Vector3(randf_range(-0.6, 0.6), randf_range(-0.4, 0.6), randf_range(-0.6, 0.6)), RAI, 0.06, 0.25, 1)
	eshot(c, "raikyu", "raiton", RAI, tg(c, t, 26.0), from, 1.0, 34.0, 0.9, {"stun": 0.6}, 1.2, 0.2)
	Sfx.play("chidori", from, 1.4, 0.6)


## Rüzgâr Kesici: kol yatay savrulur, rüzgâr dokulu ince hilal bıçak (iz bırakır) uçar ve deler; değdiği yerde kesik şok halkası
func p_futon_kazekiri_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.45)
	anim(c, "slash_b", 1.6)
	var tt = tg(c, t, 26.0)
	var from = c.global_position + Vector3.UP * 1.25 + c.face_dir() * 0.7
	VFX.gather(from, WIND, 1.0)
	after(0.12, func():
		if not live(c):
			return
		var blade = Node3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = 1.25; tm.outer_radius = 1.45; tm.rings = 32; tm.ring_segments = 6
		var arc = MeshInstance3D.new()
		arc.mesh = tm
		arc.material_override = VFX.mat_wind(Color(0.85, 1.0, 0.95), 9.0, 7.0, Vector3(1, 0, 0), 0.95)
		arc.scale = Vector3(1.0, 0.12, 0.55)
		arc.position = Vector3(0, 0, -0.7)
		blade.add_child(arc)
		var inner = MeshInstance3D.new()
		inner.mesh = tm
		inner.material_override = VFX.mat_bolt(Color(0.9, 1.0, 0.97), 1.4)
		inner.scale = Vector3(0.95, 0.05, 0.5)
		inner.position = Vector3(0, 0, -0.7)
		blade.add_child(inner)
		var pr = shot(c, from, aim_at(c, tt, from), 42.0, blade, inf(c, "futon_kazekiri_no_jutsu", 0.7, {"knock": 5.0, "kind": "heavy", "element": "fuuton", "bleed": 3.0}), null, true, 0.9, func(p, _h):
			VFX.shockwave(p, WIND, 3.5, 0.25, false, Vector3.UP)
			VFX.star(p, Color(1, 1, 1), 1.6, 0.12))
		pr.radius = 1.0
		VFX.element_trail(pr, "fuuton", WIND, 1.6)
		Projectile.trail(pr, [Color(1, 1, 1, 0.5), Color(0.8, 1, 0.92, 0.25), Color(0.7, 0.95, 0.85, 0)], 1.2, 20, 0.3, FX.tex_smoke, false))
	Sfx.play("wind", from, 1.8, 0.6)


## Kiraz Çiçeği Darbesi: havaya sıçrar, yumruğunda çakra parlar, iner — zemin örümcek ağı gibi çatlar, kayalar fırlar, toz halkası, ekran sarsılır
func p_okasho(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 10.0)
	var d = _jump_at(c, tt, 7.0, 8.0 if tt else 2.0)
	busy(c, 1.0)
	anim(c, "air", 1.0)
	var pink = Color(1, 0.6, 0.75)
	every(0.45, 0.05, func(_i, _k):
		if live(c):
			FX.burst(hand_pos(c, true), {"amount": 3, "life": 0.25, "tex": FX.tex_spark, "add": true, "size": 0.25, "radius": 0.1, "vmin": 0.5, "vmax": 1.5,
				"colors": [Color(1, 1, 1, 1), pink, Color(pink.r, pink.g, pink.b, 0)]}), Callable())
	after(0.45, func():
		if not live(c):
			return
		anim(c, "cross", 1.2)
		if c is CharacterBody3D:
			c.velocity = Vector3.DOWN * 20.0
		after(0.12, func():
			var at = gp(c.global_position + d * 0.6)
			melee_fx(c, at + Vector3.UP * 0.4, pink, 1.8, true)
			VFX.cracks(at, 9.0, Color(0.1, 0.07, 0.05, 0.95), 8.0)
			for r in [4.0, 8.0, 12.0]:
				VFX.shockwave(at + Vector3.UP * 0.1, Color(0.85, 0.75, 0.6), r, 0.5, true)
			for k in 12:
				var q = at + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
				var rk = _rock(randf_range(0.6, 1.3))
				get_tree().current_scene.add_child(rk)
				rk.global_position = gp(q) - Vector3.UP * 0.6
				rk.rotation = Vector3(randf_range(-0.6, 0.6), randf() * TAU, randf_range(-0.6, 0.6))
				var tw = rk.create_tween()
				tw.tween_property(rk, "global_position", gp(q) + Vector3.UP * randf_range(0.3, 1.2), 0.1)
				tw.tween_interval(3.0)
				tw.tween_property(rk, "global_position", gp(q) - Vector3.UP * 1.5, 0.6)
				tw.tween_callback(rk.queue_free)
			VFX.debris(at, EARTH, 50, 13.0, 0.7)
			VFX.smoke_ring(at + Vector3.UP * 0.1, 8.0, Color(0.6, 0.52, 0.42))
			shake(1.2)
			hit(c, at + Vector3.UP, 6.5, inf(c, "okasho", 2.2, {"knock": 18.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.1}))
			Sfx.play("boom", at, 0.8)))


## Akış (su seli / rüzgâr seli): ağızdan büyüyerek uzanan, akan dokulu koni; uçta sıçrama/toz; dur sonra söner
func stream_fx(from: Vector3, d: Vector3, length: float, radius: float, mat: Material, dur: float, end_fx := Callable()) -> void:
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = from
	root.look_at(from + d, Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT)
	var cm = CylinderMesh.new()
	cm.top_radius = 0.25; cm.bottom_radius = radius; cm.height = length; cm.radial_segments = 24; cm.rings = 6
	var mi = MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = mat
	mi.rotation_degrees = Vector3(-90, 0, 0)
	mi.position = Vector3(0, 0, -length * 0.5)
	root.add_child(mi)
	var inner = MeshInstance3D.new()
	var cm2 = CylinderMesh.new()
	cm2.top_radius = 0.15; cm2.bottom_radius = radius * 0.6; cm2.height = length * 0.95; cm2.radial_segments = 16
	inner.mesh = cm2
	inner.material_override = mat
	inner.rotation_degrees = Vector3(-90, 0, 0)
	inner.position = Vector3(0, 0, -length * 0.48)
	root.add_child(inner)
	root.scale = Vector3(1, 1, 0.05)
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_QUAD)
	tw.tween_interval(dur)
	tw.tween_property(root, "scale", Vector3(0.05, 0.05, 1), 0.3)
	tw.tween_callback(root.queue_free)
	if end_fx.is_valid():
		after(0.22, func(): end_fx.call(from + d * length))


func _wmat() -> Material:
	return VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.62, 0.88, 1.0), Vector3(0, 1, 0), 0.9, 0.7, 0.1)


func _windmat(alpha := 0.7) -> Material:
	return VFX.mat_wind(Color(0.82, 1.0, 0.93), 9.0, 6.0, Vector3(0, 1, 0), alpha)


## Su Mermisi: ağızda su toplanır, akan su küresi; çarpınca sıçrama
func p_suiton_suidan_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	eshot(c, "suiton_suidan_no_jutsu", "suiton", WATER, tg(c, t, 24.0), _mouth_pos(c), 0.9, 30.0, 0.8, {}, 1.0)
	Sfx.play("water", c.global_position, 1.2)


## Yayılan Su Mermileri: art arda beş akan su küresi, yelpaze
func p_suiton_suisandan(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	var tt = tg(c, t, 22.0)
	for k in 5:
		after(k * 0.1, func():
			if live(c):
				var side = c.face_dir().cross(Vector3.UP) * ((k - 2) * 0.9)
				eshot(c, "suiton_suisandan", "suiton", WATER, tt, _mouth_pos(c) + side * 0.3, 0.55, 32.0, 0.25, {}, 0.6, 0.06))
	Sfx.play("water", c.global_position, 1.3)


## Su Shurikeni: avuçta su toplanır, akan su dokulu dört kanatlı şuriken döner; çarpınca sıçrama
func p_suiton_mizu_shuriken(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 24.0)
	busy(c, 0.5)
	var from = hand_pos(c, true)
	VFX.gather(from, WATER, 1.0)
	for k in 4:
		after(0.12 + k * 0.08, func():
			if not live(c):
				return
			var star = Node3D.new()
			for j in 4:
				var bl = MeshInstance3D.new()
				var pm = PrismMesh.new()
				pm.size = Vector3(0.22, 0.42, 0.05)
				bl.mesh = pm
				bl.material_override = _wmat()
				bl.rotation = Vector3(PI * 0.5, j * PI * 0.5, 0)
				bl.position = Vector3(cos(j * PI * 0.5), 0, sin(j * PI * 0.5)) * 0.22
				star.add_child(bl)
			var pr = shot(c, from, aim_at(c, tt, from).rotated(Vector3.UP, (k - 1.5) * 0.06), 34.0, star, inf(c, "suiton_mizu_shuriken", 0.3, {"knock": 2.0, "kind": "light", "element": "suiton", "bleed": 1.0}), tt, false, 1.3, func(p, _h):
				VFX.splash(p, 1.2)
				VFX.star(p, Color(0.8, 0.95, 1.0), 1.2))
			pr.spin = Vector3(0, 28, 0)
			_etrail(pr, "suiton", WATER, 0.5))
	Sfx.play("water", from, 1.6)


## Su Dalgası Atışı: ağızdan genişleyen akan su seli (dalga), uçta dev sıçrama
func p_suiton_mizurappa(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	var d = fwd(c, t)
	var from = _mouth_pos(c)
	VFX.gather(from, WATER, 1.2)
	stream_fx(from, (d - Vector3.UP * 0.12).normalized(), 14.0, 2.6, _wmat(), 0.5, func(end):
		VFX.splash(gp(end), 3.0)
		VFX.smoke_ring(gp(end) + Vector3.UP * 0.1, 5.0, Color(0.75, 0.88, 1.0)))
	Combat.hit_zone(c, c.global_position, d, 15.0, 22.0, 3.0, inf(c, "suiton_mizurappa", 0.9, {"knock": 14.0, "kind": "heavy", "element": "suiton", "dir": d}))
	shake(0.4)
	Sfx.play("water", c.global_position, 0.8)


## Vahşi Su Dalgası: uzun süren, kalın akan su akıntısı — önündekileri sürükler; zemine su birikir
func p_water_release_wild_water_wave(c: Node3D, t: Node3D) -> void:
	busy(c, 1.4)
	var d = fwd(c, t)
	var from = _mouth_pos(c)
	VFX.gather(from, WATER, 1.4)
	stream_fx(from, (d - Vector3.UP * 0.1).normalized(), 16.0, 3.0, _wmat(), 1.1, func(end):
		VFX.splash(gp(end), 3.5)
		VFX.linger(gp(end), "suiton", WATER, 2.0, 4.0))
	every(1.2, 0.2, func(_i, _k):
		if live(c):
			Combat.hit_zone(c, c.global_position, d, 15.0, 18.0, 3.0, inf(c, "water_release_wild_water_wave", 0.25, {"knock": 9.0, "kind": "light", "element": "suiton", "dir": d}))
			VFX.splash(gp(c.global_position + d * randf_range(4.0, 14.0)), 1.6), Callable())
	shake(0.5)
	Sfx.play("water", c.global_position, 0.5)


## Köpük Dalgası: ağızdan kabaran köpük seli (su dokulu yarı saydam koni + köpük kabarcıkları) — kayganlaştırır
func p_suiton_homatsu_rappa(c: Node3D, t: Node3D) -> void:
	busy(c, 0.9)
	var d = fwd(c, t)
	var from = _mouth_pos(c)
	var foam = VFX.mat_water(Color(0.6, 0.8, 0.95), Color(0.85, 0.94, 1.0), Color(1, 1, 1), Vector3(0, 1, 0), 0.75, 0.9, 0.2)
	stream_fx(from, (d - Vector3.UP * 0.2).normalized(), 12.0, 2.4, foam, 0.7)
	for k in 10:
		after(k * 0.06, func():
			var q = gp(c.global_position + d * (2.0 + k * 1.2)) + Vector3.UP * 0.5
			VFX.puffs(q, {"amount": 26, "life": 1.8, "size": 0.45, "radius": 1.3, "vmin": 0.5, "vmax": 2.0, "dir": Vector3.UP, "spread": 60.0, "add": false,
				"colors": [Color(1, 1, 1, 0.95), Color(0.85, 0.93, 1.0, 0.7), Color(0.8, 0.9, 1.0, 0)]})
			for e in hit(c, q, 2.0, inf(c, "suiton_homatsu_rappa", 0.15, {"knock": 6.0, "kind": "light", "element": "suiton", "dir": d})):
				st(e, "slow", 3.0))
	Sfx.play("water", c.global_position, 0.8)


## Şelale Çukuru: hedefin altında su halkası belirir, dev su sütunu fışkırır (akan su dokulu silindir), havaya savurur
func p_suiton_takitsubo_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	busy(c, 0.8)
	anim(c, "crouch", 1.4)
	var at = gp(tt.global_position if tt else c.global_position + fwd(c, t) * 8.0)
	VFX.shockwave(at + Vector3.UP * 0.1, WATER, 5.0, 0.4, true)
	VFX.cracks(at, 3.0, Color(0.1, 0.15, 0.25, 0.8), 5.0)
	after(0.25, func():
		var col = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 1.2; cm.bottom_radius = 2.0; cm.height = 9.0; cm.radial_segments = 24
		col.mesh = cm
		col.material_override = _wmat()
		get_tree().current_scene.add_child(col)
		col.global_position = at + Vector3.UP * 4.5
		col.scale = Vector3(1, 0.02, 1)
		var tw = col.create_tween()
		tw.tween_property(col, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK)
		tw.tween_interval(0.6)
		tw.tween_property(col, "scale", Vector3(0.3, 0.02, 0.3), 0.35)
		tw.tween_callback(col.queue_free)
		VFX.splash(at + Vector3.UP * 8.0, 3.0)
		VFX.splash(at, 3.0)
		hit(c, at + Vector3.UP, 3.5, inf(c, "suiton_takitsubo_no_jutsu", 1.2, {"knock": 6.0, "launch": 15.0, "kind": "heavy", "element": "suiton"}))
		VFX.linger(at, "suiton", WATER, 1.8, 4.0)
		shake(0.5))
	Sfx.play("water", at, 0.6)


## Su Bağı: yerden dönen su hortumu yükselir ve hedefi içine hapseder (akan dokulu)
func p_suiton_mizu_shibari(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 16.0)
	busy(c, 0.6)
	if tt == null:
		return
	var at = tt.global_position
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = at
	for k in 2:
		var mi = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 1.0 - k * 0.2; cm.bottom_radius = 1.4 - k * 0.2; cm.height = 2.8; cm.radial_segments = 24
		mi.mesh = cm
		mi.material_override = VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.62, 0.88, 1.0), Vector3(0, 1, 0), 0.6 - k * 0.15, 0.7, 0.1)
		mi.position = Vector3.UP * 1.4
		root.add_child(mi)
		var spin = mi.create_tween().set_loops()
		spin.tween_property(mi, "rotation:y", TAU * (1 if k == 0 else -1), 0.9).from(0.0)
	root.scale = Vector3(1, 0.02, 1)
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(2.7)
	tw.tween_callback(func(): VFX.splash(at + Vector3.UP, 2.6))
	tw.tween_callback(root.queue_free)
	st(tt, "bind", 3.0)
	every(3.0, 0.5, func(_i, _k):
		if live(tt):
			tt.take_hit(inf(c, "suiton_mizu_shibari", 0.12, {"knock": 0.0, "kind": "light", "element": "suiton"})), Callable())
	VFX.splash(at, 2.0)
	Sfx.play("water", at, 0.9)


## Büyük Atılım: ağızdan dev rüzgâr seli (rüzgâr dokulu koni + hız çizgileri), yolda toz halkaları
func p_futon_toppa(c: Node3D, t: Node3D) -> void:
	busy(c, 0.9)
	var d = fwd(c, t)
	var from = _mouth_pos(c)
	VFX.gather(from, WIND, 1.3)
	stream_fx(from, d, 20.0, 3.5, _windmat(0.75), 0.4, func(end):
		VFX.smoke_ring(gp(end) + Vector3.UP * 0.1, 7.0, Color(0.85, 0.8, 0.7)))
	for k in 5:
		after(0.1 + k * 0.06, func():
			var q = gp(c.global_position + d * (3.0 + k * 3.5))
			VFX.shockwave(q + Vector3.UP * 1.2, WIND, 3.0 + k, 0.3, false, d)
			VFX.debris(q, Color(0.75, 0.68, 0.55), 6, 9.0, 0.25))
	Combat.hit_zone(c, c.global_position, d, 20.0, 28.0, 4.0, inf(c, "futon_toppa", 1.0, {"knock": 26.0, "launch": 5.0, "kind": "heavy", "element": "fuuton", "dir": d}))
	FX.speed_lines(c.global_position + Vector3.UP * 1.4, d)
	shake(0.6)
	Sfx.play("wind", c.global_position, 0.6)


## Toz Bulutu: ağızdan toz ve kumla dolu rüzgâr seli, ardından alanı kaplayan yoğun toz bulutu — içindekiler göremez
func p_futon_fujin_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.7)
	var d = fwd(c, t)
	var at = c.global_position + d * 8.0
	var dust = VFX.mat_wind(Color(0.85, 0.75, 0.58), 5.0, 4.0, Vector3(0, 1, 0), 0.8)
	stream_fx(_mouth_pos(c), d, 10.0, 3.0, dust, 0.4)
	for k in 6:
		after(0.2 + k * 0.1, func():
			VFX.puffs(at + Vector3(randf_range(-4, 4), 0.8, randf_range(-4, 4)), {"amount": 40, "life": 4.0, "size": 3.5, "radius": 2.5, "vmin": 0.3, "vmax": 1.2, "dir": Vector3.UP, "spread": 70.0, "add": false,
				"colors": [Color(0.82, 0.73, 0.58, 0.85), Color(0.78, 0.7, 0.56, 0.6), Color(0.75, 0.68, 0.55, 0)]}))
	every(4.0, 0.5, func(_i, _k):
		for e in enemies_near(c, at, 8.0):
			st(e, "slow", 1.0)
			if e.has_method("lose_target"):
				e.lose_target(1.5), Callable())
	Sfx.play("wind", c.global_position, 0.8)


## Orak Gelincik: dev savuruş — rüzgâr dokulu geniş yelpaze dalgası; havada parlak kesikler, yerde kesik izleri
func p_kamaitachi_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.9)
	anim(c, "slash_c", 1.2)
	var d = fwd(c, t)
	VFX.gather(c.global_position + Vector3.UP * 1.3 + d, WIND, 1.3)
	after(0.12, func():
		stream_fx(c.global_position + Vector3.UP * 1.2, d, 22.0, 6.0, _windmat(0.55), 0.35)
		for k in 12:
			after(k * 0.04, func():
				var q = c.global_position + d * (3.0 + k * 1.8) + d.cross(Vector3.UP) * randf_range(-4.0, 4.0)
				var cut = MeshInstance3D.new()
				var bm = BoxMesh.new()
				bm.size = Vector3(3.0, 0.04, 0.08)
				cut.mesh = bm
				cut.material_override = VFX.mat_bolt(Color(0.92, 1, 0.97), 1.6)
				get_tree().current_scene.add_child(cut)
				cut.global_position = q + Vector3.UP * randf_range(0.4, 2.6)
				cut.rotation = Vector3(0, atan2(d.x, d.z) + PI * 0.5, randf_range(-0.8, 0.8))
				var tw = cut.create_tween()
				tw.tween_property(cut, "scale", Vector3(1.4, 1, 1), 0.12)
				tw.tween_property(cut, "scale", Vector3(0.01, 1, 1), 0.2)
				tw.tween_callback(cut.queue_free)
				VFX.cracks(gp(q), 1.5, Color(0.15, 0.12, 0.1, 0.8), 5.0))
		Combat.hit_zone(c, c.global_position, d, 24.0, 30.0, 4.0, inf(c, "kamaitachi_no_jutsu", 1.3, {"knock": 18.0, "launch": 4.0, "kind": "heavy", "element": "fuuton", "bleed": 4.0, "dir": d}))
		shake(0.6))
	Sfx.play("wind", c.global_position, 0.5)


## Canavar Yırtan Avuç: dönerek kendi etrafında rüzgâr hortumu (rüzgâr dokulu dönen huni) — içine giren savrulur
func p_juha_sho(c: Node3D, t: Node3D) -> void:
	busy(c, 1.2)
	var at = c.global_position
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = at
	for k in 2:
		var mi = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 3.2 - k * 0.6; cm.bottom_radius = 1.0 - k * 0.2; cm.height = 6.0; cm.radial_segments = 24
		mi.mesh = cm
		mi.material_override = _windmat(0.6 - k * 0.15)
		mi.position = Vector3.UP * 3.0
		root.add_child(mi)
		var spin = mi.create_tween().set_loops()
		spin.tween_property(mi, "rotation:y", TAU * (1 if k == 0 else -1), 0.45).from(0.0)
	root.scale = Vector3(0.2, 0.05, 0.2)
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.25)
	tw.tween_interval(0.9)
	tw.tween_property(root, "scale", Vector3(1.4, 0.05, 1.4), 0.3)
	tw.tween_callback(root.queue_free)
	VFX.smoke_ring(at + Vector3.UP * 0.1, 6.0, Color(0.85, 0.8, 0.7))
	every(1.2, 0.15, func(_i, _k):
		VFX.debris(at, Color(0.75, 0.68, 0.55), 4, 8.0, 0.25)
		hit(c, at + Vector3.UP * 1.2, 3.8, inf(c, "juha_sho", 0.12, {"knock": 9.0, "launch": 6.0, "kind": "light", "element": "fuuton"})), Callable())
	Sfx.play("wind", at, 0.7)


## Çiçek Saçan Dans: rüzgâr dokulu dönen akış içinde binlerce pembe yaprak ve çiçek — her şeyi keser
func p_futon_hanachiri_mai(c: Node3D, t: Node3D) -> void:
	busy(c, 1.0)
	var d = fwd(c, t)
	var petal = VFX.mat_wind(Color(1.0, 0.75, 0.85), 7.0, 5.0, Vector3(0, 1, 0), 0.5)
	stream_fx(c.global_position + Vector3.UP * 1.2, d, 14.0, 3.0, petal, 0.6)
	var petals = [Color(1.0, 0.7, 0.8), Color(1.0, 0.88, 0.92), Color(0.95, 0.55, 0.7)]
	for k in 8:
		after(k * 0.07, func():
			var q = c.global_position + Vector3.UP * 1.2 + d * (2.0 + k * 1.6)
			VFX.puffs(q, {"amount": 45, "life": 1.1, "size": 0.22, "radius": 1.2 + k * 0.3, "vmin": 6, "vmax": 12, "dir": d, "spread": 55.0, "add": false,
				"colors": [petals[k % 3], petals[(k + 1) % 3], Color(1, 0.9, 0.9, 0)]})
			hit(c, q, 2.0 + k * 0.2, inf(c, "futon_hanachiri_mai", 0.18, {"knock": 3.0, "kind": "light", "element": "fuuton", "bleed": 1.0})))
	Sfx.play("wind", c.global_position, 1.1)


## Kesici Hava Dalgası: avuçlardan üç genişleyen, rüzgâr dokulu basınç halkası; yolda toz kazır
func p_zankuha(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	anim(c, "push", 1.4)
	var tt = tg(c, t, 22.0)
	VFX.gather(hand_pos(c, true), WIND, 1.0)
	for k in 3:
		after(0.15 + k * 0.12, func():
			if not live(c):
				return
			var from = hand_pos(c, k % 2 == 0)
			var dir = aim_at(c, tt, from)
			var rm = MeshInstance3D.new()
			var tm = TorusMesh.new()
			tm.inner_radius = 0.42; tm.outer_radius = 0.62; tm.rings = 32; tm.ring_segments = 8
			rm.mesh = tm
			rm.material_override = _windmat(0.8)
			rm.rotation_degrees = Vector3(90, 0, 0)
			var pr = shot(c, from, dir, 34.0, rm, inf(c, "zankuha", 0.45, {"knock": 14.0, "kind": "heavy", "element": "fuuton"}), null, true, 0.75)
			pr.radius = 1.0
			rm.create_tween().tween_property(rm, "scale", Vector3.ONE * 2.8, 0.75)
			_etrail(pr, "fuuton", WIND, 1.0)
			every(0.75, 0.1, func(_i, _k):
				if is_instance_valid(pr):
					VFX.debris(gp(pr.global_position), Color(0.75, 0.68, 0.55), 3, 5.0, 0.2), Callable())
			Sfx.play("wind", from, 1.3, 0.5))


## Büyük Hava Basıncı Dalgası: iki avuçtan dev basınç akışı — rüzgâr dokulu geniş koni, zemini kazır, ardışık şok halkaları
func p_zankukyokuha(c: Node3D, t: Node3D) -> void:
	busy(c, 1.0)
	anim(c, "push", 1.2)
	var d = fwd(c, t)
	VFX.gather(c.global_position + Vector3.UP * 1.2 + d, WIND, 1.5)
	after(0.15, func():
		stream_fx(c.global_position + Vector3.UP * 1.1 + d * 0.6, d, 22.0, 5.0, _windmat(0.7), 0.45)
		for k in 8:
			after(k * 0.05, func():
				var q = c.global_position + Vector3.UP * 1.0 + d * (3.0 + k * 2.4)
				VFX.shockwave(q, WIND, 3.0 + k * 0.6, 0.3, false, d)
				VFX.debris(gp(q), Color(0.8, 0.72, 0.58), 6, 9.0, 0.3)
				VFX.cracks(gp(q), 1.8, Color(0.15, 0.12, 0.1, 0.7), 5.0))
		Combat.hit_zone(c, c.global_position, d, 22.0, 30.0, 4.0, inf(c, "zankukyokuha", 1.4, {"knock": 22.0, "launch": 5.0, "kind": "heavy", "element": "fuuton", "dir": d}))
		shake(0.7))
	Sfx.play("wind", c.global_position, 0.5)


## Toprak çıkışı: yerden kaya sökülürken çatlak, toz halkası, moloz
func _earth_burst(at: Vector3, s := 1.0) -> void:
	VFX.cracks(at, 2.2 * s)
	VFX.debris(at, EARTH, int(12 * s), 7.0 * s, 0.45)
	VFX.smoke_ring(at + Vector3.UP * 0.1, 2.5 * s, Color(0.6, 0.5, 0.4))


## Toprak Tuğla: avuç yere vurulur, zemin çatlar; büyük tuğla blokları sökülüp sırayla fırlar, çarpınca parçalanır
func p_doton_renga_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	anim(c, "crouch", 1.5)
	var tt = tg(c, t, 24.0)
	_earth_burst(gp(c.global_position + c.face_dir()), 1.4)
	for k in 4:
		after(0.18 + k * 0.12, func():
			if not live(c):
				return
			var from = c.global_position + c.face_dir() * 1.0 + c.face_dir().cross(Vector3.UP) * (k - 1.5) * 0.7 + Vector3.UP * 0.8
			_earth_burst(gp(from), 0.7)
			var b = MB.new()
			b.add("box", Vector3.ZERO, Vector3(0.8, 0.45, 0.55), Color(0.72, 0.38, 0.28))
			b.add("box", Vector3(0, 0.23, 0), Vector3(0.82, 0.03, 0.57), Color(0.85, 0.8, 0.7))
			b.add("box", Vector3(0.2, 0.0, 0.28), Vector3(0.02, 0.45, 0.02), Color(0.85, 0.8, 0.7))
			var pr = shot(c, from, aim_at(c, tt, from), 26.0, mesh_of(b), inf(c, "doton_renga_no_jutsu", 0.4, {"knock": 6.0, "kind": "heavy", "element": "doton"}), null, false, 1.4, func(p, _h):
				impact_fx("doton", EARTH, p, 0.7))
			pr.spin = Vector3(6, 0, 3)
			Projectile.trail(pr, [Color(0.7, 0.6, 0.5, 0.6), Color(0.6, 0.5, 0.4, 0)], 0.4, 16, 0.4, FX.tex_smoke, false)
			shake(0.2))
	Sfx.play("earth", c.global_position, 1.4)


## Toprak Çakıl: avuçtan toz bulutuyla birlikte yüzlerce çakıl saçması
func p_doton_sazareishi(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	anim(c, "push", 1.6)
	var tt = tg(c, t, 18.0)
	var from = hand_pos(c, true)
	var dir = aim_at(c, tt, from)
	VFX.gather(from, EARTH, 0.9)
	after(0.12, func():
		for k in 18:
			var d = dir.rotated(Vector3.UP, randf_range(-0.3, 0.3)) + Vector3.UP * randf_range(-0.06, 0.08)
			var pr = shot(c, from, d.normalized(), randf_range(30.0, 42.0), _rock(randf_range(0.08, 0.16)), inf(c, "doton_sazareishi", 0.07, {"knock": 1.0, "kind": "light", "element": "doton"}), null, false, 0.7)
			if k % 4 == 0:
				Projectile.trail(pr, [Color(0.75, 0.65, 0.5, 0.5), Color(0.7, 0.6, 0.5, 0)], 0.25, 10, 0.3, FX.tex_smoke, false)
		VFX.puffs(from + dir, {"amount": 30, "life": 0.6, "size": 0.9, "radius": 0.4, "vmin": 8, "vmax": 14, "dir": dir, "spread": 20.0, "add": false,
			"colors": [Color(0.75, 0.65, 0.5, 0.7), Color(0.7, 0.6, 0.5, 0)]})
		VFX.debris(from, EARTH, 10, 8.0, 0.2))
	Sfx.play("earth", from, 1.8, 0.6)


## Çift İntihar Başkesme: yere dalar (toz halkası), hedefin altından çatlakla çıkar, onu boynuna kadar toprağa çeker
func p_doton_shinju_zanshu_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 16.0)
	if tt == null:
		return
	busy(c, 1.0)
	_earth_burst(c.global_position, 1.2)
	c.visible = false
	after(0.45, func():
		if not live(c):
			return
		c.visible = true
		if not live(tt):
			return
		var at = tt.global_position
		c.global_position = gp(at + (c.global_position - at).normalized() * 1.2)
		_earth_burst(at, 1.6)
		VFX.shockwave(at + Vector3.UP * 0.1, EARTH, 4.0, 0.4, true)
		st(tt, "bind", 3.0)
		tt.take_hit(inf(c, "doton_shinju_zanshu_no_jutsu", 0.5, {"knock": 0.0, "kind": "heavy", "element": "doton"}))
		var body = tt.get("model") if tt.get("model") else tt
		var y0 = body.position.y
		var tw = body.create_tween()
		tw.tween_property(body, "position:y", y0 - tt.height * 0.75, 0.25)
		tw.tween_interval(2.6)
		tw.tween_property(body, "position:y", y0, 0.3)
		Combat.popup_text(at + Vector3.UP * 1.2, "Toprağa gömüldü!", EARTH.lightened(0.3))
		shake(0.4)
		Sfx.play("earth", at, 1.0))


## Uçan Taşlar: yer çatlayıp büyük kayalar havaya kalkar, etrafında döner; sonra toz izleriyle hedefe yağar
func p_doton_tobi_tsubute(c: Node3D, t: Node3D) -> void:
	busy(c, 0.9)
	anim(c, "cast", 1.3)
	var tt = tg(c, t, 22.0)
	_earth_burst(c.global_position, 1.8)
	var rocks = []
	for k in 8:
		var r = _rock(randf_range(0.5, 0.8))
		get_tree().current_scene.add_child(r)
		var a = TAU * k / 8.0
		var q = c.global_position + Vector3(cos(a), 0, sin(a)) * 2.0
		r.global_position = gp(q) - Vector3.UP * 0.5
		r.create_tween().tween_property(r, "global_position", q + Vector3.UP * 1.8, 0.35).set_trans(Tween.TRANS_BACK)
		VFX.debris(gp(q), EARTH, 5, 5.0, 0.3)
		rocks.append(r)
	shake(0.4)
	Sfx.play("earth", c.global_position, 1.2)
	after(0.6, func():
		for k in rocks.size():
			var r: Node3D = rocks[k]
			if not is_instance_valid(r):
				continue
			var from = r.global_position
			r.queue_free()
			if live(c):
				var pr = shot(c, from, aim_at(c, tt, from), 28.0, _rock(0.6), inf(c, "doton_tobi_tsubute", 0.3, {"knock": 5.0, "kind": "heavy", "element": "doton"}), tt, false, 1.4, func(p, _h):
					impact_fx("doton", EARTH, p, 0.6))
				pr.spin = Vector3(5, 3, 0)
				Projectile.trail(pr, [Color(0.7, 0.6, 0.5, 0.6), Color(0.6, 0.5, 0.4, 0)], 0.45, 14, 0.4, FX.tex_smoke, false))


## Çamur Kayması: önündeki zemin akan çamur seline döner (çamur dokulu akış), içindekileri sürükler ve yavaşlatır
func p_doton_dosekiryu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.9)
	anim(c, "crouch", 1.4)
	var d = fwd(c, t)
	var mud = Color(0.42, 0.32, 0.22)
	var mudmat = VFX.mat_water(Color(0.22, 0.15, 0.1), Color(0.42, 0.32, 0.22), Color(0.6, 0.5, 0.38), Vector3(0, 1, 0), 0.95, 0.5, 0.15)
	stream_fx(gp(c.global_position + d) + Vector3.UP * 0.5, (d - Vector3.UP * 0.03).normalized(), 16.0, 3.0, mudmat, 0.9)
	for k in 10:
		after(k * 0.06, func():
			var q = gp(c.global_position + d * (1.5 + k * 1.6))
			VFX.puffs(q + Vector3.UP * 0.4, {"amount": 14, "life": 0.9, "size": 1.4, "radius": 1.8, "vmin": 3, "vmax": 6, "dir": d + Vector3.UP * 0.6, "spread": 30.0, "add": false,
				"colors": [mud, mud.darkened(0.3), Color(0.35, 0.28, 0.2, 0)]})
			VFX.cracks(q, 1.6, Color(0.2, 0.15, 0.1, 0.8), 6.0)
			for e in hit(c, q + Vector3.UP * 0.5, 2.2, inf(c, "doton_dosekiryu", 0.15, {"knock": 7.0, "kind": "light", "element": "doton", "dir": d})):
				st(e, "slow", 3.0))
	shake(0.4)
	Sfx.play("earth", c.global_position, 0.8)


## Toprak Yırtan Avuç: avuç yere basılır, çevre zemin dönerek yarılır — dev çatlak ağı, halka halka şok, havaya kalkan moloz
func p_doton_retsudo_tensho(c: Node3D, t: Node3D) -> void:
	busy(c, 1.0)
	anim(c, "crouch", 1.2)
	var at = gp(c.global_position + c.face_dir() * 1.0)
	VFX.gather(at + Vector3.UP * 0.3, EARTH, 1.4)
	after(0.2, func():
		VFX.cracks(at, 10.0, Color(0.1, 0.07, 0.05, 0.95), 8.0)
		for k in 3:
			after(k * 0.15, func():
				VFX.shockwave(at + Vector3.UP * 0.1, EARTH, 6.0 + k * 4.0, 0.5, true)
				for j in 5:
					VFX.debris(at + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6)), EARTH, 10, 10.0, 0.6))
		VFX.smoke_ring(at + Vector3.UP * 0.1, 9.0, Color(0.6, 0.5, 0.4))
		shake(1.0)
		for e in hit(c, at + Vector3.UP * 0.5, 7.0, inf(c, "doton_retsudo_tensho", 0.6, {"knock": 3.0, "launch": 4.0, "kind": "heavy", "element": "doton"})):
			st(e, "stun", 1.4))
	Sfx.play("earth", at, 0.7)


## Kaya Sığınağı: zemin çatlar, büyük kaya plakaları dönerek yükselir ve kubbe olur; içindekiler korunur
func p_earth_release_rock_shelter(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.7)
	anim(c, "crouch", 1.4)
	var at = gp(c.global_position)
	VFX.cracks(at, 6.0)
	VFX.smoke_ring(at + Vector3.UP * 0.1, 6.0, Color(0.6, 0.5, 0.4))
	var b = MB.new()
	for k in 14:
		var a = TAU * k / 14.0
		b.add("boulder", Vector3(cos(a) * 2.6, 1.0, sin(a) * 2.6), Vector3(1.6, 2.4, 1.4), EARTH.darkened(0.05 * (k % 3)), Vector3(0, -rad_to_deg(a), 12), 3)
	for k in 6:
		var a = TAU * k / 6.0
		b.add("boulder", Vector3(cos(a) * 1.3, 2.6, sin(a) * 1.3), Vector3(1.8, 1.0, 1.8), EARTH.lightened(0.05), Vector3.ZERO, 3)
	var dome = mesh_of(b)
	get_tree().current_scene.add_child(dome)
	dome.global_position = at - Vector3.UP * 3.2
	dome.rotation.y = -0.6
	var tw = dome.create_tween()
	tw.tween_property(dome, "global_position", at, 0.35).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(dome, "rotation:y", 0.0, 0.35)
	tw.tween_callback(func():
		VFX.shockwave(at + Vector3.UP * 0.1, EARTH, 8.0, 0.4, true)
		VFX.debris(at, EARTH, 30, 9.0, 0.6))
	tw.tween_interval(4.5)
	tw.tween_property(dome, "global_position", at - Vector3.UP * 3.5, 0.5)
	tw.tween_callback(dome.queue_free)
	shake(0.7)
	if c is Player:
		Buffs.add("rock_shelter", 5.0, {"armor": 0.15, "_name": "Kaya Sığınağı", "_desc": "kubbenin içindesin: gelen hasar çok azalır"})
	Sfx.play("earth", at, 0.8)


## Şimşek elde: avuçta kalın arklı şimşek küresi belirir (dur sn)
func _rai_hand(c: Node3D, dur: float) -> void:
	var ba = bone_attach(c, "RightHand")
	if ba == null:
		return
	var orb = VFX.lightning_ball(0.35, RAI)
	ba.add_child(orb)
	after(dur, func():
		if is_instance_valid(ba):
			ba.queue_free())


## Şimşek Darbesi: avuçta şimşek küresi toplanır, atılıp vurur — çarpınca kalın dallar, yıldız, yanık çatlak, felç
func p_raigeki(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	_rai_hand(c, 0.5)
	VFX.gather(hand_pos(c, true), RAI, 1.0)
	busy(c, 0.6)
	after(0.15, func():
		_jump_at(c, tt, 0.0, 14.0 if tt else 3.0))
	after(0.3, func():
		if not live(c):
			return
		anim(c, "cross", 1.6)
		var at = c.global_position + Vector3.UP * 1.1 + c.face_dir() * 1.2
		melee_fx(c, at, RAI, 1.3)
		impact_fx("raiton", RAI, at, 1.0)
		for e in hit(c, at, 1.8, inf(c, "raigeki", 1.3, {"knock": 8.0, "kind": "heavy", "element": "raiton"})):
			st(e, "stun", 0.9)
		Sfx.play("thunder", at, 1.4))


## Şimşek Yatay El Bıçağı: el şimşekle kaplanır, yatay savrulur — parlayan şimşek yayı, yay boyunca arklar
func p_raigyaku_suihei_choppu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 6.0)
	var d = _face(c, tt)
	_rai_hand(c, 0.5)
	busy(c, 0.6)
	after(0.12, func():
		_jump_at(c, tt, 0.0, 10.0 if tt else 3.0))
	after(0.25, func():
		if not live(c):
			return
		anim(c, "slash_b", 1.8)
		var at = c.global_position + Vector3.UP * 1.2
		var arc = MeshInstance3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = 1.6; tm.outer_radius = 1.8; tm.rings = 32; tm.ring_segments = 6
		arc.mesh = tm
		arc.material_override = VFX.mat_bolt(RAI, 2.4)
		arc.scale = Vector3(1, 0.1, 1)
		get_tree().current_scene.add_child(arc)
		arc.global_position = at + d * 0.3
		var tw = arc.create_tween()
		tw.tween_property(arc, "scale", Vector3(1.3, 0.02, 1.3), 0.25)
		tw.tween_callback(arc.queue_free)
		for k in 7:
			var q = at + d.rotated(Vector3.UP, deg_to_rad(-70.0 + k * 23.0)) * 1.8
			VFX.bolt(q, q + Vector3(randf_range(-1, 1), randf_range(-0.6, 0.6), randf_range(-1, 1)), RAI, 0.1, 0.3, 2)
		Combat.hit_zone(c, c.global_position, d, 3.2, 75.0, 2.0, inf(c, "raigyaku_suihei_choppu", 1.3, {"knock": 10.0, "kind": "heavy", "element": "raiton", "stun": 0.5}))
		shake(0.4)
		Sfx.play("thunder", c.global_position, 1.7, 0.6))


## Şimşek Yılan Balığı: elden kalın, kıvrılan şimşek akımı uzanır; hedefi sarar ve sürekli çarpar (kıvılcım, felç)
func p_raiton_ikazuchi_unagi(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	busy(c, 0.9)
	anim(c, "push", 1.3)
	_rai_hand(c, 2.0)
	if tt == null:
		return
	st(tt, "bind", 2.0)
	every(2.0, 0.07, func(_i, _k):
		if live(c) and live(tt):
			VFX.bolt(hand_pos(c, true), tt.global_position + Vector3.UP * 1.0, RAI, 0.22, 0.12, 3)
			VFX.bolt(tt.global_position + Vector3(randf_range(-0.6, 0.6), 0.2, randf_range(-0.6, 0.6)), tt.global_position + Vector3(randf_range(-0.6, 0.6), 1.8, randf_range(-0.6, 0.6)), RAI, 0.08, 0.12, 1), Callable())
	every(2.0, 0.4, func(_i, _k):
		if live(tt):
			VFX.star(tt.global_position + Vector3.UP, RAI, 1.4, 0.1)
			tt.take_hit(inf(c, "raiton_ikazuchi_unagi", 0.25, {"knock": 0.0, "kind": "light", "element": "raiton"})), Callable())
	Sfx.play("thunder", tt.global_position, 1.5)


## Şimşek Tazısı: avuçtan şimşek dokulu bir tazı fırlar, yerde koşarak hedefi izler; çarpınca dev şimşek patlaması
func p_raiton_raiju_tsuiga(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 26.0)
	busy(c, 0.6)
	_rai_hand(c, 0.4)
	VFX.gather(hand_pos(c, true), RAI, 1.2)
	after(0.2, func():
		if not live(c):
			return
		var from = gp(c.global_position + c.face_dir() * 1.0) + Vector3.UP * 0.7
		var hound = Node3D.new()
		var m = VFX.mat_bolt(RAI, 2.0)
		for part in [[Vector3(0, 0, 0), Vector3(0.55, 0.45, 1.1)], [Vector3(0, 0.2, 0.62), Vector3(0.38, 0.34, 0.5)], [Vector3(0, 0.15, -0.7), Vector3(0.12, 0.12, 0.6)]]:
			var mi = MeshInstance3D.new()
			mi.mesh = SphereMesh.new()
			mi.material_override = m
			mi.position = part[0]
			mi.scale = part[1]
			hound.add_child(mi)
		var arcs = VFX.lightning_ball(0.6, RAI)
		hound.add_child(arcs)
		var dir = aim_at(c, tt, from)
		dir.y = 0
		var pr = shot(c, from, dir.normalized(), 24.0, hound, inf(c, "raiton_raiju_tsuiga", 1.1, {"knock": 10.0, "kind": "heavy", "element": "raiton", "stun": 0.8}), tt, false, 2.0, func(p, _h):
			impact_fx("raiton", RAI, p, 1.4))
		pr.homing_turn = 4.0
		pr.radius = 0.8
		_etrail(pr, "raiton", RAI, 0.8))
	Sfx.play("chidori", c.global_position, 1.2)


## Yakın dövüş vuruşu + isabette detaylı darbe efekti (yıldız, yönlü şok halkası, kıvılcım; ağırsa çatlak/toz)
func mhit(c: Node3D, pos: Vector3, r: float, info: Dictionary, exclude: Array = []) -> Array:
	var hs = hit(c, pos, r, info, exclude)
	if not hs.is_empty():
		var heavy = String(info.get("kind", "")) == "heavy"
		var s = clampf(0.8 + float(info.get("knock", 4.0)) * 0.04 + absf(float(info.get("launch", 0.0))) * 0.03, 0.8, 1.8)
		var col = Color(1.0, 0.85, 0.55) if not info.has("element") else (Color(0.65, 0.85, 1.0) if info["element"] == "raiton" else Color(0.85, 1.0, 0.92))
		melee_fx(c, hs[0].global_position + Vector3.UP * 1.0, col, s if heavy else s * 0.7, heavy and s > 1.3)
	return hs


func _mfx(c: Node3D, at: Vector3, col: Color, s := 1.0) -> void:
	melee_fx(c, at, col, s * 1.2, s >= 1.2)


## Fuma tipi büyük şuriken (dört kavisli kanat) — gölge şurikeninde kullanılır
func _fuma(s := 1.0) -> Node3D:
	var root = Node3D.new()
	var steel = StandardMaterial3D.new()
	steel.albedo_color = Color(0.55, 0.57, 0.62)
	steel.metallic = 0.8
	steel.roughness = 0.3
	for k in 4:
		var bl = MeshInstance3D.new()
		var pm = PrismMesh.new()
		pm.size = Vector3(0.28 * s, 0.75 * s, 0.03 * s)
		pm.left_to_right = 0.0
		bl.mesh = pm
		bl.material_override = steel
		bl.rotation = Vector3(PI * 0.5, k * PI * 0.5, 0)
		bl.position = Vector3(cos(k * PI * 0.5), 0, sin(k * PI * 0.5)) * 0.32 * s
		root.add_child(bl)
	var hub = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.12 * s; cm.bottom_radius = 0.12 * s; cm.height = 0.05 * s
	hub.mesh = cm
	hub.material_override = steel
	root.add_child(hub)
	return root


## Gölge Shuriken: dev fuma şuriken döner; gölgesinde saklı ikinci şuriken hedefe yaklaşınca yerden ayrılıp başka açıdan vurur
func p_kage_shuriken_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	var tt = tg(c, t, 30.0)
	var from = hand_pos(c, true) + Vector3.UP * 0.3
	var dir = aim_at(c, tt, from)
	var info = inf(c, "kage_shuriken_no_jutsu", 0.6, {"knock": 3.0, "kind": "heavy", "bleed": 3.0})
	var p1 = shot(c, from, dir, 28.0, _fuma(1.5), info, tt, false, 1.6, func(p, _h):
		melee_fx(c, p, Color(0.85, 0.9, 1.0), 1.0))
	p1.spin = Vector3(0, 26, 0)
	p1.radius = 0.8
	VFX.trail(p1, 0.6, Color(1, 1, 1, 0.7), Color(0.75, 0.8, 0.9, 0.4), Color(0.6, 0.65, 0.75, 0), 14, 0.0)
	Sfx.play("whoosh", from, 1.2, 0.6)
	after(0.22, func():
		if not is_instance_valid(p1):
			return
		var g = gp(p1.global_position) + Vector3.UP * 0.15
		VFX.smoke_ring(g, 1.6, Color(0.1, 0.1, 0.12))
		var side = dir.cross(Vector3.UP).normalized() * (1.0 if randf() < 0.5 else -1.0)
		var p2 = shot(c, g, (dir + side * 0.5 + Vector3.UP * 0.25).normalized(), 30.0, _fuma(1.2), info, tt, false, 1.4, func(p, _h):
			melee_fx(c, p, Color(0.85, 0.9, 1.0), 1.0))
		p2.spin = Vector3(0, -30, 0)
		p2.homing_turn = 7.0
		p2.radius = 0.7
		VFX.trail(p2, 0.5, Color(0.6, 0.6, 0.7, 0.7), Color(0.3, 0.3, 0.35, 0.4), Color(0.1, 0.1, 0.12, 0), 14, 0.0)
		Combat.popup_text(g + Vector3.UP * 1.2, "Gölgeden ikinci!", Color(0.8, 0.8, 0.9)))


## Gölge Senbon: zilli senbon çifti — ilki görünür, ikincisi gölgesinde gizli; zil sesiyle şaşırtır
func p_kage_senbon(c: Node3D, t: Node3D) -> void:
	busy(c, 0.4)
	var tt = tg(c, t, 25.0)
	var from = hand_pos(c, true)
	for wave in 2:
		after(wave * 0.18, func():
			if not live(c):
				return
			for k in 3:
				var nd = Node3D.new()
				var b = MB.new()
				b.add("cyl", Vector3.ZERO, Vector3(0.014, 0.42, 0.014), Color(0.88, 0.89, 0.93), Vector3(90, 0, 0), 4)
				if wave == 0:
					b.add("sphere", Vector3(0, -0.03, -0.24), Vector3(0.06, 0.06, 0.06), Color(0.85, 0.7, 0.3))   # zil
				nd.add_child(mesh_of(b))
				var d = aim_at(c, tt, from).rotated(Vector3.UP, deg_to_rad((k - 1) * 3.0)) + Vector3.UP * (0.015 * (wave * 2 - 1))
				var pr = shot(c, from - Vector3.UP * 0.1 * wave, d.normalized(), 52.0, nd, inf(c, "kage_senbon", 0.14, {"knock": 0.5, "kind": "light", "bleed": 1.0}), null, false, 0.9, func(p, _h):
					VFX.star(p, Color(1, 1, 1), 0.8, 0.1))
				VFX.trail(pr, 0.06, Color(1, 1, 1, 0.9), Color(0.8, 0.85, 0.95, 0.4), Color(0.7, 0.75, 0.85, 0), 10, 0.3))
	Sfx.play("seal", from, 2.2, 0.4)
	Sfx.play("whoosh", from, 1.9, 0.4)


## Geçici Felç: el mührü, gözler parlar; hedefin üstüne kırmızı-mor felç halkaları iner, beden kaskatı (bağ çizgileri)
func p_kanashibari_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 16.0)
	busy(c, 0.6)
	anim(c, "cast", 1.2)
	if tt == null:
		return
	var col = Color(0.75, 0.3, 0.85)
	VFX.gather(c.global_position + Vector3.UP * 1.7, col, 0.8)
	for k in 4:
		after(0.1 + k * 0.1, func():
			if live(tt):
				VFX.shockwave(tt.global_position + Vector3.UP * (2.2 - k * 0.5), col, 2.4 - k * 0.3, 0.35, true))
	for k in 6:
		var a = k * TAU / 6.0
		tether(func(): return tt.global_position + Vector3(cos(a) * 0.9, 1.7, sin(a) * 0.9) if live(tt) else Vector3.ZERO,
			func(): return tt.global_position + Vector3(cos(a + 2.1) * 0.9, 0.15, sin(a + 2.1) * 0.9) if live(tt) else Vector3.ZERO, 0.04, VFX.mat_bolt(col, 1.6), 2.5)
	VFX.cracks(gp(tt.global_position), 1.4, Color(0.25, 0.1, 0.3, 0.8), 3.0)
	st(tt, "stun", 2.5)
	Combat.popup_text(tt.global_position + Vector3.UP * 2.3, "Felç!", col)
	Sfx.play("genjutsu", tt.global_position, 1.2)


## Sis klonu ortak: yoğun sis bulutundan yarı saydam kopyalar
func _mist_clones(c: Node3D, center: Vector3, n: int, life: float, spread: float) -> void:
	VFX.puffs(center + Vector3.UP, {"amount": 90, "life": 3.0, "size": 3.0, "radius": spread, "vmin": 0.2, "vmax": 0.8, "dir": Vector3.UP, "spread": 60.0, "add": false,
		"colors": [Color(0.85, 0.9, 0.95, 0.55), Color(0.8, 0.85, 0.9, 0.35), Color(0.8, 0.85, 0.9, 0)]})
	for k in n:
		var a = (k - (n - 1) * 0.5) * 0.55
		var at = center + c.face_dir().rotated(Vector3.UP, a) * spread * 0.6
		var d = decoy(c, at, life, func(pos):
			VFX.puffs(pos + Vector3.UP, {"amount": 30, "life": 0.8, "size": 1.4, "radius": 0.6, "vmin": 1, "vmax": 3, "dir": Vector3.UP, "spread": 80.0, "add": false,
				"colors": [Color(0.9, 0.93, 0.97, 0.7), Color(0.85, 0.9, 0.95, 0)]}))
		VFX.smoke_ring(gp(at) + Vector3.UP * 0.1, 1.5, Color(0.85, 0.9, 0.95))


## Sis Hizmetkârı: koyu sis basar, içinden sis askerleri çıkar — düşmanı oyalar, yavaşlatır
func p_kasumi_jusha_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.6)
	anim(c, "cast", 1.2)
	var center = c.global_position + c.face_dir() * 3.5
	_mist_clones(c, center, 5, 7.0, 4.0)
	for e in enemies_near(c, center, 10.0):
		st(e, "slow", 3.0)
	Sfx.play("genjutsu", center, 0.9)


## Pus Klonu: üç titreşen pus kopyası etrafa dağılır
func p_oboro_bunshin_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.4)
	_mist_clones(c, c.global_position, 3, 6.0, 3.0)
	Sfx.play("poof", c.global_position, 1.2)


## Köpük Klonu: ağızdan sabun köpüğü yağar, saydam yanardöner köpük bir beden yükselir; dokununca patlar
func p_bubble_clone_technique(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.5)
	var at = c.global_position + c.face_dir().cross(Vector3.UP) * 2.5
	var bub = Node3D.new()
	var m = VFX.mat_water(Color(0.55, 0.8, 0.9), Color(0.85, 0.75, 1.0), Color(1, 1, 1), Vector3(0, 1, 0), 0.3, 0.9, 0.3)
	for part in [[Vector3(0, 0.5, 0), 1.0], [Vector3(0, 1.25, 0), 0.75], [Vector3(0, 1.8, 0), 0.5]]:
		var mi = MeshInstance3D.new()
		mi.mesh = SphereMesh.new()
		mi.material_override = m
		mi.position = part[0]
		mi.scale = Vector3.ONE * part[1]
		bub.add_child(mi)
	get_tree().current_scene.add_child(bub)
	bub.global_position = gp(at)
	bub.scale = Vector3.ONE * 0.05
	bub.create_tween().tween_property(bub, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK)
	VFX.puffs(at + Vector3.UP, {"amount": 50, "life": 1.2, "size": 0.25, "radius": 1.0, "vmin": 1, "vmax": 3, "dir": Vector3.UP, "spread": 90.0, "add": false,
		"colors": [Color(0.9, 0.95, 1.0, 0.8), Color(0.85, 0.8, 1.0, 0.5), Color(0.8, 0.9, 1.0, 0)]})
	var d = decoy(c, at, 8.0, func(pos):
		if is_instance_valid(bub):
			bub.queue_free()
		VFX.splash(pos + Vector3.UP, 2.4)
		VFX.puffs(pos + Vector3.UP, {"amount": 70, "life": 0.8, "size": 0.35, "radius": 1.0, "vmin": 4, "vmax": 9, "dir": Vector3.UP, "spread": 180.0, "add": false,
			"colors": [Color(0.9, 0.95, 1.0, 0.9), Color(0.85, 0.8, 1.0, 0)]})
		for e in hit(c, pos + Vector3.UP, 3.5, inf(c, "bubble_clone_technique", 0.5, {"knock": 6.0, "kind": "heavy", "element": "suiton"})):
			st(e, "stun", 1.5)
		Sfx.play("water", pos, 1.3))
	if d:
		d.visible = false
		every(8.0, 0.1, func(_i, _k):
			if is_instance_valid(bub) and is_instance_valid(d):
				bub.global_position = d.global_position, Callable())
	after(8.2, func():
		if is_instance_valid(bub):
			bub.queue_free())
	Sfx.play("water", at, 1.5)


## Tuzak: yere teller gerilir, patlayıcı etiketler gizlenir; basan düşmana dört yandan kunai yağar ve etiketler patlar
func p_bubitorappu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	anim(c, "crouch", 1.6)
	var d = fwd(c, t)
	var at = gp(c.global_position + d * 4.0)
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = at
	var wire = StandardMaterial3D.new()
	wire.albedo_color = Color(0.9, 0.9, 0.85)
	wire.emission_enabled = true
	wire.emission = Color(0.4, 0.4, 0.35)
	for k in 4:
		var a = k * TAU / 4.0 + 0.4
		var w = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(4.0, 0.012, 0.012)
		w.mesh = bm
		w.material_override = wire
		w.position = Vector3(0, 0.18, 0)
		w.rotation.y = a
		root.add_child(w)
		var tag = MeshInstance3D.new()
		var tm = BoxMesh.new()
		tm.size = Vector3(0.16, 0.01, 0.3)
		tag.mesh = tm
		var tmat = StandardMaterial3D.new()
		tmat.albedo_color = Color(0.95, 0.9, 0.75)
		tag.material_override = tmat
		tag.position = Vector3(cos(a) * 1.8, 0.03, sin(a) * 1.8)
		root.add_child(tag)
	VFX.cracks(at, 1.0, Color(0.2, 0.15, 0.1, 0.5), 20.0)
	var fired := {"v": false}
	every(20.0, 0.12, func(_i, _k):
		if fired["v"] or not is_instance_valid(root):
			return
		if not enemies_near(c, at, 2.0).is_empty():
			fired["v"] = true
			for k in 8:
				var a = k * TAU / 8.0
				var q = at + Vector3(cos(a) * 4.5, 1.2, sin(a) * 4.5)
				var b = MB.new()
				b.add("cone", Vector3(0, 0, 0.12), Vector3(0.05, 0.2, 0.015), Color(0.6, 0.62, 0.66), Vector3(90, 0, 0), 4)
				b.add("cyl", Vector3(0, 0, -0.06), Vector3(0.025, 0.14, 0.025), Color(0.2, 0.2, 0.22), Vector3(90, 0, 0), 6)
				shot(c, q, (at + Vector3.UP - q).normalized(), 40.0, mesh_of(b), inf(c, "bubitorappu", 0.2, {"knock": 1.0, "kind": "light", "bleed": 2.0}), null, false, 0.4)
			after(0.25, func():
				impact_fx("katon", Color(1, 0.55, 0.15), at + Vector3.UP * 0.4, 1.4)
				hit(c, at + Vector3.UP, 3.8, inf(c, "bubitorappu", 1.2, {"knock": 14.0, "launch": 9.0, "kind": "heavy", "element": "katon"}))
				if is_instance_valid(root):
					root.queue_free()), func():
		if is_instance_valid(root):
			root.queue_free())


## Çakra Bağı: avuçtan kırmızı çakra bantları fırlar, hedefin bedenini X şeklinde sarar — kıpırdayamaz
func p_chakura_kontororu_baku(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	busy(c, 0.6)
	anim(c, "push", 1.3)
	if tt == null:
		return
	var col = Color(1.0, 0.3, 0.35)
	VFX.gather(hand_pos(c, true), col, 0.9)
	for k in 2:
		tether(func(): return hand_pos(c, k == 0) if live(c) else Vector3.ZERO, func(): return tt.global_position + Vector3.UP * 1.0 if live(tt) else Vector3.ZERO, 0.05, VFX.mat_bolt(col, 1.4), 0.5)
	after(0.3, func():
		if not live(tt):
			return
		var root = Node3D.new()
		tt.add_child(root)
		for k in 6:
			var band = MeshInstance3D.new()
			var tm = TorusMesh.new()
			tm.inner_radius = 0.42; tm.outer_radius = 0.48; tm.rings = 24; tm.ring_segments = 4
			band.mesh = tm
			band.material_override = VFX.mat_bolt(col, 1.6)
			band.position = Vector3.UP * (0.4 + (k % 3) * 0.5)
			band.rotation = Vector3(deg_to_rad(30.0 if k < 3 else -30.0), 0, deg_to_rad(20.0 if k < 3 else -20.0))
			root.add_child(band)
		var tw = root.create_tween()
		tw.tween_interval(2.6)
		tw.tween_callback(root.queue_free)
		st(tt, "bind", 2.6)
		VFX.star(tt.global_position + Vector3.UP, col, 1.6))
	Sfx.play("seal", tt.global_position, 1.2)


## Hızlı Rüzgâr Duvarı: kullanıcının etrafında dönen beyaz rüzgâr kubbesi — mermileri savurur, yaklaşanı iter
func p_fujinheki(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.5)
	var root = Node3D.new()
	c.add_child(root)
	for k in 2:
		var mi = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = 2.4 - k * 0.3; sm.height = (2.4 - k * 0.3) * 2.0
		mi.mesh = sm
		mi.material_override = _windmat(0.55 - k * 0.15)
		mi.position = Vector3.UP * 1.0
		root.add_child(mi)
		var spin = mi.create_tween().set_loops()
		spin.tween_property(mi, "rotation:y", TAU * (1 if k == 0 else -1), 0.6).from(0.0)
	root.scale = Vector3.ONE * 0.1
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.2)
	tw.tween_interval(3.8)
	tw.tween_property(root, "scale", Vector3.ONE * 1.4, 0.2)
	tw.tween_callback(root.queue_free)
	VFX.smoke_ring(gp(c.global_position) + Vector3.UP * 0.1, 4.0, Color(0.85, 0.8, 0.7))
	every(4.0, 0.1, func(_i, _k):
		if not live(c):
			return
		for p in get_tree().get_nodes_in_group("projectiles"):
			if p.get("shooter") != c and p.global_position.distance_to(c.global_position) < 3.0:
				VFX.shockwave(p.global_position, WIND, 1.5, 0.2, false)
				p.queue_free()
		for e in enemies_near(c, c.global_position, 2.8):
			if e.get("velocity") != null:
				e.velocity += (e.global_position - c.global_position).normalized() * 6.0, Callable())
	if c is Player:
		Buffs.add("fujinheki", 4.0, {"armor": 0.6, "_name": "Rüzgâr Duvarı"})
	Sfx.play("wind", c.global_position, 0.9)


## Genjutsu Bağı: göz göze gelince hedefin etrafında kırmızı genjutsu girdabı döner, olduğu yerde donar
func p_genjutsu_shibari(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	busy(c, 0.6)
	anim(c, "cast", 1.2)
	if tt == null:
		return
	var col = Color(0.85, 0.15, 0.25)
	var sw = MeshInstance3D.new()
	var tm = TorusMesh.new()
	tm.inner_radius = 0.9; tm.outer_radius = 1.4; tm.rings = 32; tm.ring_segments = 6
	sw.mesh = tm
	sw.material_override = VFX.mat_spiral(Color(1, 0.6, 0.65), col, 5.0, 3.0, 6.0, 1.4, Vector3.UP)
	get_tree().current_scene.add_child(sw)
	sw.global_position = tt.global_position + Vector3.UP * 0.1
	var tw = sw.create_tween()
	tw.tween_property(sw, "rotation:y", TAU * 3.0, 3.0)
	tw.parallel().tween_property(sw, "global_position:y", sw.global_position.y + 1.8, 3.0)
	tw.tween_callback(sw.queue_free)
	VFX.gather(tt.global_position + Vector3.UP * 1.6, col, 0.9)
	st(tt, "stun", 3.0)
	Combat.popup_text(tt.global_position + Vector3.UP * 2.4, "Genjutsu!", col)
	Sfx.play("genjutsu", tt.global_position, 0.8)


## Senbon Yağmuru: göğe atılan şemsiye dönerek açılır, hedefin üstünde iğne yağmuru bırakır
func p_jouro_senbon(c: Node3D, t: Node3D) -> void:
	busy(c, 0.5)
	anim(c, "throw", 1.5)
	var tt = tg(c, t, 24.0)
	var at = tt.global_position if tt else c.global_position + fwd(c, t) * 10.0
	var um = Node3D.new()
	var canopy = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.05; cm.bottom_radius = 1.4; cm.height = 0.5; cm.radial_segments = 16
	canopy.mesh = cm
	var cmat = StandardMaterial3D.new()
	cmat.albedo_color = Color(0.45, 0.35, 0.22)
	canopy.material_override = cmat
	um.add_child(canopy)
	var stick = MeshInstance3D.new()
	var sm = CylinderMesh.new()
	sm.top_radius = 0.03; sm.bottom_radius = 0.03; sm.height = 1.4
	stick.mesh = sm
	stick.material_override = cmat
	stick.position = Vector3.DOWN * 0.6
	um.add_child(stick)
	get_tree().current_scene.add_child(um)
	um.global_position = hand_pos(c, true)
	var tw = um.create_tween()
	tw.tween_property(um, "global_position", at + Vector3.UP * 9.0, 0.45).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(um, "rotation:y", TAU * 3.0, 1.6)
	tw.tween_interval(1.1)
	tw.tween_callback(func():
		FX.smoke_puff(um.global_position, 1.2, 10)
		um.queue_free())
	after(0.5, func():
		for k in 40:
			after(randf() * 0.9, func():
				var b = MB.new()
				b.add("cyl", Vector3.ZERO, Vector3(0.014, 0.4, 0.014), Color(0.88, 0.89, 0.93), Vector3(90, 0, 0), 4)
				var q = at + Vector3(randf_range(-1.2, 1.2), 8.6, randf_range(-1.2, 1.2))
				var pr = shot(c, q, (at + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)) - q).normalized(), 40.0, mesh_of(b), inf(c, "jouro_senbon", 0.07, {"knock": 0.3, "kind": "light", "bleed": 1.0}), null, false, 0.5)
				if k % 3 == 0:
					VFX.trail(pr, 0.05, Color(1, 1, 1, 0.8), Color(0.8, 0.85, 0.95, 0.3), Color(0.7, 0.75, 0.85, 0), 8, 0.3)))
	Sfx.play("whoosh", c.global_position, 1.7)


## Kurbağaya Dönüştürme: hedefin üstünde mühür çemberi, büyük duman patlaması; hedef küçük bir kurbağaya döner
func p_kaeru_kaeru_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	busy(c, 0.6)
	anim(c, "push", 1.2)
	if tt == null:
		return
	var col = Color(0.5, 0.85, 0.4)
	summon_circle(tt.global_position, 1.4, col, 0.5)
	VFX.gather(tt.global_position + Vector3.UP, col, 1.0)
	after(0.3, func():
		if not live(tt):
			return
		FX.smoke_puff(tt.global_position + Vector3.UP, 1.4, 22)
		VFX.smoke_ring(gp(tt.global_position) + Vector3.UP * 0.1, 2.5, Color(0.95, 0.95, 0.95))
		var body = tt.get("model") if tt.get("model") else null
		var b = MB.new()
		b.add("sphere", Vector3(0, 0.25, 0), Vector3(0.6, 0.45, 0.65), Color(0.4, 0.65, 0.3))
		b.add("sphere", Vector3(0, 0.18, 0.08), Vector3(0.45, 0.3, 0.45), Color(0.85, 0.85, 0.6))
		for ex in [-1.0, 1.0]:
			b.add("sphere", Vector3(ex * 0.15, 0.5, 0.2), Vector3(0.14, 0.14, 0.14), Color(0.95, 0.9, 0.3))
			b.add("sphere", Vector3(ex * 0.15, 0.5, 0.26), Vector3(0.06, 0.06, 0.04), Color(0.05, 0.05, 0.05))
			b.add("sphere", Vector3(ex * 0.25, 0.08, -0.1), Vector3(0.18, 0.12, 0.3), Color(0.38, 0.6, 0.28))
		var frog = mesh_of(b)
		tt.add_child(frog)
		if body:
			body.visible = false
		st(tt, "stun", 4.0)
		Combat.popup_text(tt.global_position + Vector3.UP * 1.5, "Vrak!", col)
		after(4.0, func():
			if is_instance_valid(frog):
				frog.queue_free()
			if is_instance_valid(body):
				body.visible = true
			if live(tt):
				FX.smoke_puff(tt.global_position + Vector3.UP, 1.0, 12)))
	Sfx.play("poof", tt.global_position, 1.0)


## Zil Sesi Klonu: zil sesi halka halka yayılır, hedefin çevresinde sıra sıra sahte kopyalar belirir
func p_genjutsu_suzune_bunshin(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	busy(c, 0.6)
	anim(c, "cast", 1.2)
	Sfx.play("seal", c.global_position, 2.0)
	var gold = Color(1, 0.88, 0.45)
	for k in 4:
		after(k * 0.12, func():
			if live(c):
				VFX.shockwave(c.global_position + Vector3.UP * 1.3, gold, 4.0 + k * 3.0, 0.4, false))
	if tt == null:
		return
	for k in 6:
		var a = TAU * k / 6.0
		var at = tt.global_position + Vector3(cos(a), 0, sin(a)) * 2.6
		decoy(c, at, 3.0)
		VFX.smoke_ring(gp(at) + Vector3.UP * 0.1, 1.2, Color(0.95, 0.9, 0.75))
	st(tt, "stun", 2.2)
	Combat.popup_text(tt.global_position + Vector3.UP * 2.4, "Çın çın...", gold)


## Karga Klonu: beden onlarca kargaya patlar (siyah tüyler, duman), sürü düşmanı sarar; asıl beden yanda belirir
func p_karasu_bunshin_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.7)
	var tt = tg(c, t, 20.0)
	var black = Color(0.05, 0.05, 0.07)
	VFX.puffs(c.global_position + Vector3.UP, {"amount": 60, "life": 1.0, "size": 0.25, "radius": 0.8, "vmin": 3, "vmax": 8, "dir": Vector3.UP, "spread": 120.0, "add": false,
		"colors": [Color(0.08, 0.08, 0.1, 1), Color(0.12, 0.1, 0.15, 0.6), Color(0.1, 0.1, 0.1, 0)]})
	for k in 30:
		var bird = Node3D.new()
		var b = MB.new()
		b.add("sphere", Vector3(0, 0.0, 0.05), Vector3(0.14, 0.12, 0.26), black)
		b.add("cone", Vector3(0, 0.0, 0.2), Vector3(0.04, 0.1, 0.04), Color(0.2, 0.2, 0.2), Vector3(90, 0, 0), 4)
		for sx in [-1.0, 1.0]:
			b.add("box", Vector3(sx * 0.2, 0.02, 0.0), Vector3(0.36, 0.015, 0.16), black, Vector3(0, 0, sx * 15.0))
		bird.add_child(mesh_of(b))
		get_tree().current_scene.add_child(bird)
		bird.global_position = c.global_position + Vector3.UP * randf_range(0.4, 1.8)
		var end = (tt.global_position if tt else c.global_position + fwd(c, t) * 8.0) + Vector3(randf_range(-2, 2), randf_range(0.5, 2.5), randf_range(-2, 2))
		bird.look_at(end, Vector3.UP)
		var tw = bird.create_tween()
		tw.tween_property(bird, "global_position", end, 0.6 + randf() * 0.3)
		tw.tween_callback(bird.queue_free)
	decoy(c, c.global_position, 6.0)
	if tt:
		after(0.8, func():
			for e in enemies_near(c, tt.global_position, 3.0):
				st(e, "stun", 1.5)
				e.take_hit(inf(c, "karasu_bunshin_no_jutsu", 0.4, {"knock": 2.0, "kind": "light"}))
			VFX.puffs(tt.global_position + Vector3.UP, {"amount": 40, "life": 1.2, "size": 0.2, "radius": 1.2, "vmin": 1, "vmax": 3, "dir": Vector3.DOWN, "spread": 90.0, "add": false,
				"colors": [Color(0.06, 0.06, 0.08, 1), Color(0.1, 0.1, 0.12, 0)]}))
	Sfx.play("whoosh", c.global_position, 1.3)


## Kurbağa Kata: doğa enerjisi toplanır (turuncu girdap), gözlerde bilge pigmenti; 12 sn aura vuruşlara eşlik eder
func p_kawazu_kumite(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.6)
	anim(c, "fold", 1.0)
	VFX.gather(c.global_position + Vector3.UP, SAGE, 1.6)
	var sw = MeshInstance3D.new()
	var tm = TorusMesh.new()
	tm.inner_radius = 1.2; tm.outer_radius = 1.6; tm.rings = 32; tm.ring_segments = 6
	sw.mesh = tm
	sw.material_override = VFX.mat_spiral(Color(1, 0.9, 0.6), SAGE, 5.0, 2.0, 5.0, 1.4, Vector3.UP)
	c.add_child(sw)
	sw.position = Vector3.UP * 0.2
	var tw = sw.create_tween()
	tw.tween_property(sw, "position:y", 2.2, 0.9)
	tw.parallel().tween_property(sw, "scale", Vector3.ONE * 0.2, 0.9)
	tw.tween_callback(sw.queue_free)
	if c is Player:
		Buffs.add("kawazu_kumite", 12.0, {"melee": 1.6, "reach": 1.5, "_name": "Kurbağa Kata", "_desc": "doğa enerjisi aurası: yakın dövüş +%60, menzil +%50"})
	every(12.0, 0.25, func(_i, _k):
		if live(c):
			FX.burst(c.global_position + Vector3.UP * 1.0, {"amount": 4, "life": 0.6, "tex": FX.tex_spark, "add": true, "size": 0.3, "radius": 0.6, "vmin": 0.5, "vmax": 1.5, "dir": Vector3.UP, "spread": 30.0,
				"colors": [Color(1, 0.85, 0.5, 0.8), SAGE, Color(SAGE.r, SAGE.g, SAGE.b, 0)]}), Callable())
	Sfx.play("seal", c.global_position, 0.8)


## Örümcek Ağı Bağı: avuçtan parlak ağ topu fırlar, hedefte ışınsal bir ağa açılıp onu yere yapıştırır
func p_kumo_shibari(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	busy(c, 0.5)
	var from = hand_pos(c, true)
	var ball = Node3D.new()
	ball.add_child(_web(0.5))
	var pr = shot(c, from, aim_at(c, tt, from), 30.0, ball, inf(c, "kumo_shibari", 0.3, {"knock": 0.0, "kind": "light"}), tt, false, 1.0, func(p, h):
		var w = _web(1.8)
		get_tree().current_scene.add_child(w)
		w.global_position = p
		w.look_at(p + (p - c.global_position).normalized(), Vector3.UP)
		var tw = w.create_tween()
		tw.tween_interval(3.0)
		tw.tween_property(w, "scale", Vector3.ONE * 0.01, 0.3)
		tw.tween_callback(w.queue_free)
		if h and live(h):
			st(h, "bind", 3.0)
			Combat.popup_text(h.global_position + Vector3.UP * 2.3, "Ağa takıldı!", WEB))
	ball.create_tween().set_loops().tween_property(ball, "rotation:z", TAU, 0.4).from(0.0)
	VFX.trail(pr, 0.15, Color(1, 1, 1, 0.9), Color(0.9, 0.9, 0.85, 0.4), Color(0.9, 0.9, 0.85, 0), 12, 0.2)
	Sfx.play("whoosh", from, 1.6, 0.5)


## Işınsal örümcek ağı modeli (r yarıçap): parlak ışınlar + halkalar
func _web(r: float) -> Node3D:
	var root = Node3D.new()
	var m = VFX.mat_bolt(Color(0.95, 0.95, 0.9), 1.2)
	for k in 12:
		var sp = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(r * 2.0, r * 0.012 + 0.01, 0.01)
		sp.mesh = bm
		sp.material_override = m
		sp.rotation.z = k * PI / 12.0
		root.add_child(sp)
	for j in 5:
		var ring = MeshInstance3D.new()
		var tm = TorusMesh.new()
		var rr = r * (0.2 + j * 0.2)
		tm.inner_radius = rr - 0.012; tm.outer_radius = rr; tm.rings = 24; tm.ring_segments = 3
		ring.mesh = tm
		ring.material_override = m
		ring.rotation.x = PI * 0.5
		root.add_child(ring)
	return root


const SYRUP := Color(0.93, 0.88, 0.75)


func _syrup_mat() -> Material:
	return VFX.mat_water(Color(0.75, 0.68, 0.52), Color(0.9, 0.85, 0.72), Color(1, 0.98, 0.92), Vector3(0, 1, 0), 0.92, 0.6, 0.12)


## Çiçek Ağı: avuçlardan üç çiçek biçimli ağ fırlar, uçarken açılır; hedefe ve çevresine yapışır
func p_kumo_soka(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 22.0)
	busy(c, 0.7)
	anim(c, "throw", 1.3)
	var from = hand_pos(c, true)
	for k in 3:
		after(k * 0.12, func():
			if not live(c):
				return
			var w = _web(0.5)
			var pr = shot(c, from, aim_at(c, tt, from).rotated(Vector3.UP, (k - 1) * 0.15), 26.0, w, inf(c, "kumo_soka", 0.3, {"knock": 0.0, "kind": "light"}), null, false, 1.1, func(p, _h):
				var big = _web(2.4)
				get_tree().current_scene.add_child(big)
				big.global_position = gp(p) + Vector3.UP * 0.05
				big.rotation.x = -PI * 0.5
				var tw = big.create_tween()
				tw.tween_interval(3.5)
				tw.tween_property(big, "scale", Vector3.ONE * 0.01, 0.3)
				tw.tween_callback(big.queue_free)
				for e in enemies_near(c, p, 2.8):
					st(e, "bind", 3.5)
					Combat.popup_text(e.global_position + Vector3.UP * 2.3, "Ağa takıldı!", WEB))
			w.create_tween().tween_property(w, "scale", Vector3.ONE * 3.0, 0.5)
			VFX.trail(pr, 0.2, Color(1, 1, 1, 0.8), Color(0.9, 0.9, 0.85, 0.4), Color(0.9, 0.9, 0.85, 0), 12, 0.2))
	Sfx.play("whoosh", from, 1.1)


## Yankı Matkabı: yumruktaki düzenek ses dalgasını titreştirir — vuruş anında iç içe ses halkaları, iç kulak sarsılır
func p_kyomeisen(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 7.0)
	var d = _jump_at(c, tt, 0.0, 12.0 if tt else 3.0)
	busy(c, 0.6)
	var sound = Color(0.85, 0.8, 1.0)
	after(0.2, func():
		if not live(c):
			return
		anim(c, "cross", 1.6)
		var at = c.global_position + Vector3.UP * 1.2 + d * 1.0
		for k in 5:
			after(k * 0.05, func():
				VFX.shockwave(at + d * k * 0.6, sound, 1.2 + k * 0.9, 0.3, false, d))
		for e in mhit(c, at, 2.0, inf(c, "kyomeisen", 0.6, {"knock": 4.0, "kind": "heavy"})):
			st(e, "stun", 1.2)
			st(e, "slow", 4.0)
			Combat.popup_text(e.global_position + Vector3.UP * 2.3, "Denge bozuldu!", sound)
		Sfx.play("genjutsu", at, 1.6))


## Şurup Mermileri: ağızdan kıvamlı açık şurup akıntısı — değdiği hedef ve zemin yapışkan
func p_mizuame_teppo(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	busy(c, 0.7)
	var from = _mouth_pos(c)
	VFX.gather(from, SYRUP, 0.9)
	for k in 3:
		after(0.12 + k * 0.14, func():
			if not live(c):
				return
			var blob = MeshInstance3D.new()
			blob.mesh = SphereMesh.new()
			blob.material_override = _syrup_mat()
			blob.scale = Vector3(0.6, 0.5, 1.4)
			var pr = shot(c, from, aim_at(c, tt, from), 24.0, blob, inf(c, "mizuame_teppo", 0.25, {"knock": 2.0, "kind": "light", "element": "suiton"}), null, false, 1.2, func(p, h):
				VFX.splash(p, 1.4)
				_oil_pool(c, p, 2.0, 4.0)
				if h and live(h):
					st(h, "bind", 2.0))
			VFX.trail(pr, 0.4, Color(1, 0.98, 0.92, 0.9), SYRUP, Color(SYRUP.r, SYRUP.g, SYRUP.b, 0), 16, 0.0))
	Sfx.play("water", from, 0.9)


## Gizli İğne Fırlatıcı: bilekteki boru düzeneğinden sessiz zehirli iğne seli (yeşil zehir izi), isabette zehir buharı
func p_shikomishindan(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	busy(c, 0.4)
	anim(c, "push", 1.8)
	var from = hand_pos(c, true)
	var poison = Color(0.45, 0.85, 0.35)
	for k in 6:
		after(k * 0.05, func():
			var b = MB.new()
			b.add("cyl", Vector3.ZERO, Vector3(0.014, 0.3, 0.014), Color(0.7, 0.85, 0.6), Vector3(90, 0, 0), 4)
			var pr = shot(c, from, aim_at(c, tt, from).rotated(Vector3.UP, randf_range(-0.05, 0.05)), 55.0, mesh_of(b), inf(c, "shikomishindan", 0.12, {"knock": 0.2, "kind": "light", "poison": 4.0}), null, false, 0.8, func(p, _h):
				VFX.puffs(p, {"amount": 10, "life": 0.8, "size": 0.5, "radius": 0.3, "vmin": 0.5, "vmax": 1.5, "dir": Vector3.UP, "spread": 60.0, "add": false,
					"colors": [Color(0.5, 0.9, 0.4, 0.7), Color(0.4, 0.8, 0.3, 0)]}))
			VFX.trail(pr, 0.05, Color(0.85, 1, 0.8, 0.9), poison, Color(poison.r, poison.g, poison.b, 0), 10, 0.4))
	Sfx.play("kunai", from, 1.6, 0.4)


## Beş Mühür Bariyeri: «禁» yazılı beş etiket yere çakılır, aralarında mor mühür duvarı örülür — içerideki kapanır
func p_gofu_kekkai(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 18.0)
	busy(c, 0.9)
	var at = gp(tt.global_position if tt else c.global_position + fwd(c, t) * 6.0)
	var col = Color(0.65, 0.4, 1.0)
	var pts = []
	for k in 5:
		var a = TAU * k / 5.0
		pts.append(at + Vector3(cos(a), 0, sin(a)) * 3.0)
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = at
	for k in 5:
		var p0: Vector3 = pts[k] - at
		var p1: Vector3 = pts[(k + 1) % 5] - at
		var wall = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(p0.distance_to(p1), 3.2, 0.04)
		wall.mesh = bm
		wall.material_override = VFX.mat_wind(col.lightened(0.3), 2.0, 8.0, Vector3(0, 1, 0), 0.55)
		wall.position = (p0 + p1) * 0.5 + Vector3.UP * 1.6
		wall.rotation.y = -atan2(p1.z - p0.z, p1.x - p0.x)
		root.add_child(wall)
		var tag = Label3D.new()
		tag.text = "禁"
		tag.font_size = 96
		tag.pixel_size = 0.004
		tag.modulate = Color(0.75, 0.1, 0.12)
		tag.outline_modulate = Color(0.97, 0.93, 0.8)
		tag.outline_size = 40
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.position = p0 + Vector3.UP * 0.5
		root.add_child(tag)
		VFX.star(pts[k] + Vector3.UP * 0.5, col, 1.0)
	root.scale = Vector3(1, 0.01, 1)
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(6.0)
	tw.tween_property(root, "scale", Vector3(1, 0.01, 1), 0.3)
	tw.tween_callback(root.queue_free)
	VFX.shockwave(at + Vector3.UP * 0.1, col, 7.0, 0.5, true)
	for e in enemies_near(c, at, 3.0):
		st(e, "bind", 6.0)
		Combat.popup_text(e.global_position + Vector3.UP * 2.3, "Mühür bariyeri!", col)
	Sfx.play("seal", at, 0.8)


## Lastik Beden: beden yumuşar, kollar-bacaklar uzar; gerilme dalgası
func p_nan_no_kaizo(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.5)
	VFX.gather(c.global_position + Vector3.UP, Color(0.85, 0.7, 0.55), 1.0)
	if c.get("model") and c.model.overlay:
		var ov = c.model.overlay
		var tw = c.create_tween()
		tw.tween_property(ov, "limb_scale", 1.35, 0.3).set_trans(Tween.TRANS_ELASTIC)
		after(15.0, func():
			if is_instance_valid(c) and c.get("model") and c.model.overlay:
				c.model.overlay.limb_scale = 1.0)
	VFX.shockwave(c.global_position + Vector3.UP, Color(0.85, 0.7, 0.55), 2.5, 0.3, false)
	if c is Player:
		Buffs.add("nan_no_kaizo", 15.0, {"reach": 1.8, "_name": "Lastik Beden", "_desc": "uzuvlar uzadı: yakın dövüş menzili +%80"})
	Sfx.play("whoosh", c.global_position, 0.7)


## İkame Beden: deri kabuk gibi soyulur, içindeki beden geri sıçrar; kabuk darbeyi alır
func p_narikawari_no_jutsu(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.3)
	if c is Player:
		Buffs.add("narikawari", 4.0, {"armor": 0.0, "_name": "İkame Beden", "_desc": "sonraki darbe ikame bedene gider"})
	var shell = decoy(c, c.global_position, 4.0, func(pos):
		VFX.puffs(pos + Vector3.UP, {"amount": 30, "life": 0.8, "size": 0.4, "radius": 0.6, "vmin": 2, "vmax": 5, "dir": Vector3.UP, "spread": 90.0, "add": false,
			"colors": [Color(0.9, 0.85, 0.8, 0.9), Color(0.8, 0.75, 0.7, 0)]}))
	VFX.puffs(c.global_position + Vector3.UP, {"amount": 25, "life": 0.6, "size": 0.35, "radius": 0.5, "vmin": 2, "vmax": 4, "dir": Vector3.UP, "spread": 80.0, "add": false,
		"colors": [Color(0.95, 0.9, 0.85, 0.9), Color(0.9, 0.85, 0.8, 0)]})
	c.global_position = gp(c.global_position - c.face_dir() * 4.0)
	VFX.smoke_ring(c.global_position + Vector3.UP * 0.1, 1.4, Color(0.9, 0.9, 0.9))
	Sfx.play("poof", c.global_position, 1.1)


## Bin Karga: gökyüzü kararır, yüzlerce karga hedefin etrafında kapkara bir fırtına olur — göremez, saldıramaz
func p_sanzengarasu_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	busy(c, 0.6)
	anim(c, "cast", 1.2)
	if tt == null:
		return
	var black = Color(0.05, 0.05, 0.07)
	var birds = []
	for k in 50:
		var b = MB.new()
		b.add("sphere", Vector3(0, 0, 0.05), Vector3(0.14, 0.12, 0.26), black)
		for sx in [-1.0, 1.0]:
			b.add("box", Vector3(sx * 0.2, 0.02, 0), Vector3(0.38, 0.015, 0.16), black, Vector3(0, 0, sx * 15.0))
		var bird = mesh_of(b)
		get_tree().current_scene.add_child(bird)
		bird.global_position = c.global_position + Vector3.UP * 1.5
		birds.append(bird)
	every(3.2, 1.0 / 30.0, func(i, _k):
		if not live(tt):
			return
		for n in birds.size():
			var a = i * 0.22 + n * 0.7
			var r = 1.2 + (n % 6) * 0.35
			var tgt = tt.global_position + Vector3(cos(a) * r, 0.3 + (n % 8) * 0.35, sin(a) * r)
			birds[n].global_position = birds[n].global_position.lerp(tgt, 0.25)
			birds[n].rotation.y = -a, func():
		for bd in birds:
			if is_instance_valid(bd):
				bd.queue_free())
	VFX.puffs(tt.global_position + Vector3.UP * 1.2, {"amount": 80, "life": 2.5, "size": 0.18, "radius": 2.0, "vmin": 0.5, "vmax": 2.0, "dir": Vector3.DOWN, "spread": 90.0, "add": false,
		"colors": [Color(0.06, 0.06, 0.08, 1), Color(0.1, 0.1, 0.12, 0)]})
	st(tt, "stun", 3.0)
	if tt.has_method("lose_target"):
		tt.lose_target(3.0)
	Sfx.play("genjutsu", tt.global_position, 1.0)


## Yol Kaybettirme: hedefin ayaklarının altında yeşil-mor dönen halkalar; düz yürüdüğünü sanıp daire çizer
func p_sly_mind_affect_technique(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 20.0)
	busy(c, 0.5)
	anim(c, "cast", 1.2)
	if tt == null:
		return
	var col = Color(0.55, 0.85, 0.6)
	var sw = MeshInstance3D.new()
	var tm = TorusMesh.new()
	tm.inner_radius = 1.6; tm.outer_radius = 2.2; tm.rings = 32; tm.ring_segments = 4
	sw.mesh = tm
	sw.material_override = VFX.mat_spiral(Color(0.9, 1, 0.9), col, 4.0, 2.0, 3.0, 1.2, Vector3.UP)
	tt.add_child(sw)
	sw.position = Vector3.UP * 0.05
	sw.scale = Vector3(1, 0.05, 1)
	var tw = sw.create_tween()
	tw.tween_property(sw, "rotation:y", TAU * 4.0, 6.0)
	tw.tween_callback(sw.queue_free)
	st(tt, "slow", 6.0)
	if tt.has_method("lose_target"):
		tt.lose_target(6.0)
	Combat.popup_text(tt.global_position + Vector3.UP * 2.3, "Kayboldu...", col)
	Sfx.play("genjutsu", tt.global_position, 1.3)


## Ses Bastırma: flütten karşı ses dalgası — halka halka yayılır, mermileri ve ses tekniklerini söndürür
func p_sosai_no_ne(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.5)
	anim(c, "cast", 1.4)
	var col = Color(0.85, 0.8, 1.0)
	for k in 5:
		after(k * 0.08, func():
			if live(c):
				VFX.shockwave(c.global_position + Vector3.UP * 1.3, col, 3.0 + k * 2.5, 0.35, false)
				VFX.shockwave(c.global_position + Vector3.UP * 0.1, col, 3.0 + k * 2.5, 0.35, true))
	for p in get_tree().get_nodes_in_group("projectiles"):
		if p.get("shooter") != c and p.global_position.distance_to(c.global_position) < 10.0:
			VFX.star(p.global_position, col, 1.2)
			p.queue_free()
	for e in enemies_near(c, c.global_position, 6.0):
		st(e, "stun", 0.8)
	Sfx.play("genjutsu", c.global_position, 2.0)


## İpli Bıçaklar: çakra telleriyle havaya kalkan kunailer kullanıcının etrafında bekler, sonra her yandan hedefe saplanır
func p_soshujin(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 22.0)
	busy(c, 0.8)
	anim(c, "cast", 1.3)
	var knives = []
	for k in 8:
		var b = MB.new()
		b.add("cone", Vector3(0, 0, 0.14), Vector3(0.06, 0.24, 0.018), Color(0.62, 0.64, 0.68), Vector3(90, 0, 0), 4)
		b.add("cyl", Vector3(0, 0, -0.07), Vector3(0.028, 0.16, 0.028), Color(0.2, 0.2, 0.22), Vector3(90, 0, 0), 6)
		b.add("torus", Vector3(0, 0, -0.17), Vector3(0.05, 0.05, 0.01), Color(0.2, 0.2, 0.22), Vector3(90, 0, 0), 8)
		var kn = mesh_of(b)
		get_tree().current_scene.add_child(kn)
		var a = TAU * k / 8.0
		var q = c.global_position + Vector3(cos(a) * 1.6, 1.0 + sin(a * 2.0) * 0.4, sin(a) * 1.6)
		kn.global_position = c.global_position + Vector3.UP
		kn.create_tween().tween_property(kn, "global_position", q, 0.3)
		knives.append(kn)
		var wire = StandardMaterial3D.new()
		wire.albedo_color = Color(0.7, 0.85, 1.0)
		wire.emission_enabled = true
		wire.emission = Color(0.4, 0.6, 1.0)
		tether(func(): return hand_pos(c, k % 2 == 0) if live(c) else Vector3.ZERO, func(): return kn.global_position if is_instance_valid(kn) else Vector3.ZERO, 0.012, wire, 0.55)
	after(0.55, func():
		for kn in knives:
			if not is_instance_valid(kn):
				continue
			var from = kn.global_position
			kn.queue_free()
			if live(c):
				var b2 = MB.new()
				b2.add("cone", Vector3(0, 0, 0.14), Vector3(0.06, 0.24, 0.018), Color(0.62, 0.64, 0.68), Vector3(90, 0, 0), 4)
				b2.add("cyl", Vector3(0, 0, -0.07), Vector3(0.028, 0.16, 0.028), Color(0.2, 0.2, 0.22), Vector3(90, 0, 0), 6)
				var pr = shot(c, from, aim_at(c, tt, from), 34.0, mesh_of(b2), inf(c, "soshujin", 0.22, {"knock": 1.0, "kind": "light", "bleed": 2.0}), tt, false, 1.4, func(p, _h):
					VFX.star(p, Color(1, 1, 1), 0.9, 0.1))
				pr.homing_turn = 7.0
				VFX.trail(pr, 0.06, Color(0.9, 0.95, 1, 0.9), Color(0.6, 0.75, 1.0, 0.4), Color(0.5, 0.6, 0.9, 0), 10, 0.3))
	Sfx.play("kunai", c.global_position, 1.4)


## Kara Yağmur: ağızdan göğe kara yağ fışkırır, kara bulut olur; yoğun yağlı damlalar alana yağar (ateşle tutuşur)
func p_suiton_kokuu_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	var tt = tg(c, t, 22.0)
	var at = gp(tt.global_position if tt else c.global_position + fwd(c, t) * 10.0)
	var black = Color(0.1, 0.08, 0.06)
	stream_fx(_mouth_pos(c), Vector3.UP, 7.0, 0.6, VFX.mat_water(Color(0.03, 0.02, 0.02), Color(0.12, 0.1, 0.08), Color(0.3, 0.27, 0.22), Vector3(0, 1, 0), 0.95, 0.4, 0.1), 0.3)
	VFX.puffs(at + Vector3.UP * 8.5, {"amount": 50, "life": 2.2, "size": 3.0, "radius": 5.0, "vmin": 0.1, "vmax": 0.5, "dir": Vector3.UP, "spread": 60.0, "add": false,
		"colors": [Color(0.12, 0.1, 0.1, 0.85), Color(0.15, 0.13, 0.12, 0.6), Color(0.15, 0.13, 0.12, 0)]})
	for k in 60:
		after(0.4 + randf() * 1.2, func():
			var q = at + Vector3(randf_range(-6, 6), 8.0, randf_range(-6, 6))
			var dr = MeshInstance3D.new()
			dr.mesh = SphereMesh.new()
			dr.material_override = VFX.mat_water(Color(0.03, 0.02, 0.02), Color(0.12, 0.1, 0.08), Color(0.4, 0.35, 0.3), Vector3(0, 1, 0), 0.95, 0.5, 0.1)
			dr.scale = Vector3(0.12, 0.3, 0.12)
			get_tree().current_scene.add_child(dr)
			dr.global_position = q
			var tw = dr.create_tween()
			tw.tween_property(dr, "global_position", gp(q), 0.45)
			tw.tween_callback(func():
				VFX.puffs(gp(q) + Vector3.UP * 0.1, {"amount": 4, "life": 0.4, "size": 0.15, "radius": 0.1, "vmin": 1, "vmax": 2, "dir": Vector3.UP, "spread": 70.0, "add": false,
					"colors": [Color(0.1, 0.08, 0.06, 0.9), Color(0.1, 0.08, 0.06, 0)]})
				dr.queue_free()))
	after(1.0, func():
		_oil_pool(c, at, 6.0, 8.0))
	Sfx.play("water", at, 0.5)


## Şurup Gölü: ağızdan yere kıvamlı şurup dalgası akar, geniş yapışkan göl olur
func p_suiton_mizuame_nabara(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	var d = fwd(c, t)
	var at = gp(c.global_position + d * 5.0)
	stream_fx(_mouth_pos(c), (d - Vector3.UP * 0.35).normalized(), 6.0, 1.6, _syrup_mat(), 0.5, func(end):
		VFX.splash(gp(end), 2.0))
	after(0.3, func():
		var pool = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 4.5; cm.bottom_radius = 4.5; cm.height = 0.06; cm.radial_segments = 32
		pool.mesh = cm
		pool.material_override = _syrup_mat()
		get_tree().current_scene.add_child(pool)
		pool.global_position = at + Vector3.UP * 0.04
		pool.scale = Vector3(0.1, 1, 0.1)
		var tw = pool.create_tween()
		tw.tween_property(pool, "scale", Vector3.ONE, 0.5)
		tw.tween_interval(9.0)
		tw.tween_property(pool, "scale", Vector3(0.1, 1, 0.1), 0.5)
		tw.tween_callback(pool.queue_free))
	every(10.0, 0.5, func(_i, _k):
		for e in enemies_near(c, at, 4.5):
			st(e, "bind", 0.6), Callable())
	Sfx.play("water", at, 0.6)


## İç Ses: içindeki öfkeli ikinci benlik genjutsuyu parçalar — pembe patlama, "KAI!"; sersemlik/bağ biter, kısa bağışıklık
func p_uchi_naru_sakura(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.4)
	var pink = Color(1, 0.55, 0.75)
	if c.has_method("clear_status"):
		c.clear_status()
	elif c.get("status") is Dictionary:
		for k in ["stun", "bind", "slow"]:
			c.status.erase(k)
	if c is Player:
		Buffs.add("uchi_naru", 6.0, {"_name": "İç Ses", "_desc": "genjutsu kırıldı; kısa süre etkilenmezsin"})
	VFX.star(c.global_position + Vector3.UP * 1.7, pink, 3.0, 0.2)
	VFX.shockwave(c.global_position + Vector3.UP * 1.7, pink, 5.0, 0.35, false)
	FX.burst(c.global_position + Vector3.UP * 1.7, {"amount": 30, "life": 0.5, "tex": FX.tex_spark, "add": true, "size": 0.35, "radius": 0.4, "vmin": 4, "vmax": 9,
		"colors": [Color(1, 1, 1, 1), pink, Color(pink.r, pink.g, pink.b, 0)]})
	if c is Player:
		VFX.screen_lines(0.3, 0.6, pink)
	Combat.popup_text(c.global_position + Vector3.UP * 2.6, "KAI!!", pink)
	Sfx.play("seal", c.global_position, 1.4)


## Kalın kurbağa dili şeridi (kabarcıklı pembe)
func _tongue_mat() -> Material:
	return VFX.mat_water(Color(0.75, 0.35, 0.42), Color(0.95, 0.55, 0.6), Color(1, 0.8, 0.82), Vector3(0, 0, 1), 1.0, 0.3, 0.05)


## Kurbağa Dili Bağı: ağızdan kalın, kabarcıklı dil fırlar, hedefe dolanıp sana doğru çeker
func p_zessenbaku(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	busy(c, 0.8)
	if tt == null:
		return
	tether(func(): return _mouth_pos(c) if live(c) else Vector3.ZERO, func(): return tt.global_position + Vector3.UP if live(tt) else _mouth_pos(c), 0.28, _tongue_mat(), 0.9)
	after(0.12, func():
		if not live(tt):
			return
		var coil = MeshInstance3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = 0.42; tm.outer_radius = 0.62; tm.rings = 24; tm.ring_segments = 10
		coil.mesh = tm
		coil.material_override = _tongue_mat()
		coil.position = Vector3.UP * 1.0
		tt.add_child(coil)
		var tw = coil.create_tween()
		tw.tween_interval(0.8)
		tw.tween_callback(coil.queue_free)
		st(tt, "bind", 1.0))
	after(0.3, func():
		if live(tt) and tt.get("velocity") != null:
			var v = c.global_position - tt.global_position
			tt.velocity = v.normalized() * minf(22.0, v.length() * 2.5) + Vector3.UP * 3.0)
	Sfx.play("whoosh", c.global_position, 0.8)


## Kurbağa Dili Kesiği: ağızdan ince, sertleşmiş dil ışık hızında yatay savrulur — keskin iz bırakır
func p_zessenzan(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 8.0)
	var d = _face(c, tt)
	busy(c, 0.5)
	var tip := {"a": -1.2}
	tether(func(): return _mouth_pos(c) if live(c) else Vector3.ZERO, func(): return _mouth_pos(c) + d.rotated(Vector3.UP, tip["a"]) * 6.5 if live(c) else Vector3.ZERO, 0.07, VFX.mat_bolt(Color(0.75, 0.85, 1.0), 1.5), 0.35)
	every(0.35, 1.0 / 30.0, func(_i, k):
		tip["a"] = lerpf(-1.2, 1.2, k), Callable())
	_arc_cut(_mouth_pos(c), d, -70.0, 70.0, Color(0.8, 0.9, 1.0), 6.0)
	Combat.hit_zone(c, c.global_position, d, 6.5, 70.0, 2.5, inf(c, "zessenzan", 1.0, {"knock": 8.0, "kind": "heavy", "bleed": 2.0}))
	Sfx.play("whoosh", c.global_position, 1.0)


## Kâğıt yaprağı (gerçek düzlem, iki yüz)
func _sheet(s := 0.3, col := PAPER) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var pm = QuadMesh.new()
	pm.size = Vector2(s, s * 1.3)
	mi.mesh = pm
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = col * 0.25
	mi.material_override = m
	mi.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
	return mi


## Kâğıt fırtınası: from'dan to'ya n yaprak döne döne uçar (yay çizerek)
func paper_storm(from: Vector3, to: Vector3, n: int, dur := 0.6, spread := 1.5, s := 0.3, col := PAPER) -> void:
	for k in n:
		var sh = _sheet(s * randf_range(0.7, 1.3), col)
		get_tree().current_scene.add_child(sh)
		var a = from + Vector3(randf_range(-0.4, 0.4), randf_range(-0.3, 0.5), randf_range(-0.4, 0.4))
		sh.global_position = a
		var mid = a.lerp(to, 0.5) + Vector3(randf_range(-spread, spread), randf_range(0.2, spread), randf_range(-spread, spread))
		var b = to + Vector3(randf_range(-0.6, 0.6), randf_range(-0.4, 0.6), randf_range(-0.6, 0.6))
		var t0 = randf() * 0.15
		var tw = sh.create_tween()
		tw.tween_interval(t0)
		tw.tween_method(func(u):
			if is_instance_valid(sh):
				sh.global_position = a.lerp(mid, u).lerp(mid.lerp(b, u), u)
				sh.rotate_y(0.3)
				sh.rotate_x(0.2), 0.0, 1.0, dur)
		tw.tween_callback(sh.queue_free)


## Kâğıt Klonu: beden yüzlerce yaprağa dağılıp yanında yeniden birleşir; klon patlayıcı kâğıt — vurulunca patlar
func p_kami_bunshin(c: Node3D, t: Node3D) -> void:
	busy(c, 0.6)
	var at = gp(c.global_position + c.face_dir().cross(Vector3.UP) * 3.0)
	paper_storm(c.global_position + Vector3.UP, at + Vector3.UP, 70, 0.5, 1.2)
	VFX.shockwave(c.global_position + Vector3.UP, PAPER, 2.0, 0.3, false)
	Sfx.play("whoosh", c.global_position, 1.6, 0.6)
	after(0.5, func():
		if not live(c):
			return
		decoy(c, at, 8.0, func(pos):
			paper_storm(pos + Vector3.UP, pos + Vector3.UP * 2.0, 50, 0.4, 3.0)
			impact_fx("katon", Color(1, 0.6, 0.2), pos + Vector3.UP, 1.1)
			hit(c, pos + Vector3.UP, 3.0, inf(c, "kami_bunshin", 0.7, {"knock": 10.0, "kind": "heavy", "element": "katon"})))
		if c is Player:
			Buffs.add("stealth_kami", 2.5, {"_name": "Kâğıt Klon", "_desc": "düşmanlar klona yöneldi"}))


## Kâğıt Kelebekler: kollardan kanat çırpan kâğıt kelebek sürüsü kopar, mor ışıltıyla düşmanların yüzüne kapanır
func p_kami_chocho(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	var foes = enemies_near(c, c.global_position + fwd(c, t) * 8.0, 9.0)
	var tt = tg(c, t, 18.0)
	if tt and not tt in foes:
		foes.append(tt)
	Sfx.play("wind", c.global_position, 1.8, 0.5)
	for e in foes.slice(0, 5):
		for k in 14:
			var bf = Node3D.new()
			for sx in [-1.0, 1.0]:
				var w = _sheet(0.16, PAPER if k % 3 else PAPER_V)
				w.rotation = Vector3(PI * 0.5, 0, 0)
				w.position = Vector3(sx * 0.08, 0, 0)
				bf.add_child(w)
				var fl = w.create_tween().set_loops()
				fl.tween_property(w, "rotation:z", sx * 1.1, 0.08)
				fl.tween_property(w, "rotation:z", -sx * 0.2, 0.08)
			get_tree().current_scene.add_child(bf)
			var from = hand_pos(c, k % 2 == 0) + Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.4), randf_range(-0.3, 0.3))
			bf.global_position = from
			var mid = from.lerp(e.global_position, 0.5) + Vector3(randf_range(-2, 2), randf_range(1, 3), randf_range(-2, 2))
			var tw = bf.create_tween()
			tw.tween_property(bf, "global_position", mid, 0.35)
			tw.tween_property(bf, "global_position", e.global_position + Vector3.UP * e.height * 0.8 + Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.2), randf_range(-0.3, 0.3)), 0.3)
			tw.tween_interval(2.6)
			tw.tween_callback(bf.queue_free)
		after(0.65, func():
			if live(e):
				st(e, "stun", 3.0)
				VFX.star(e.global_position + Vector3.UP * e.height * 0.8, PAPER_V, 1.4)
				e.take_hit(inf(c, "kami_chocho", 0.4, {"knock": 0.0, "kind": "light"}))
				Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Görüşü kapandı!", PAPER_V))


## Shiki Dansı: kollar kâğıda dağılır — iki koldan akan kâğıt seli etrafında döner (kalkan), sonra hepsi kâğıt şuriken olup hedefe yağar
func p_shikigami_no_mai(c: Node3D, t: Node3D) -> void:
	busy(c, 1.4)
	anim(c, "cast", 1.0)
	for k in 2:
		paper_storm(hand_pos(c, k == 0), c.global_position + Vector3.UP * 1.2 + c.face_dir().cross(Vector3.UP) * (k * 2 - 1) * 2.0, 40, 0.5, 1.0)
	var ring = Node3D.new()
	get_tree().current_scene.add_child(ring)
	var stars = []
	for k in 36:
		var mi = Node3D.new()
		mi.add_child(mesh_of(_paper_star()))
		ring.add_child(mi)
		stars.append(mi)
	if c is Player:
		Buffs.add("shikigami", 1.2, {"armor": 0.3, "_name": "Kâğıt Kalkan"})
	every(1.1, 1.0 / 30.0, func(_i, k):
		if live(c) and is_instance_valid(ring):
			ring.global_position = c.global_position + Vector3.UP * 1.1
			for n in stars.size():
				var a = TAU * n / stars.size() + k * 9.0
				stars[n].position = Vector3(cos(a) * (1.5 + sin(n) * 0.35), sin(n * 1.7) * 0.9, sin(a) * (1.5 + sin(n) * 0.35))
				stars[n].rotation.y = k * 30.0 + n, func():
		if not is_instance_valid(ring):
			return
		var tt = tg(c, t, 30.0)
		for n in stars.size():
			var from = stars[n].global_position
			var pr = shot(c, from, aim_at(c, tt, from).rotated(Vector3.UP, randf_range(-0.1, 0.1)), 45.0, mesh_of(_paper_star()), inf(c, "shikigami_no_mai", 0.08, {"knock": 1.0, "kind": "light", "bleed": 1.0}), null, false, 1.2)
			pr.spin = Vector3(0, 40, 0)
			if n % 3 == 0:
				VFX.trail(pr, 0.12, Color(1, 1, 1, 0.9), PAPER_V.lightened(0.4), Color(PAPER_V.r, PAPER_V.g, PAPER_V.b, 0), 10, 0.3)
		ring.queue_free()
		Sfx.play("whoosh", c.global_position, 1.3))


## Kâğıt Mızrak Ormanı: avuç yere — zemin kâğıt dalgasıyla kabarır, hedefin altından keskin kâğıt mızraklar fışkırır
func p_kami_yari(c: Node3D, t: Node3D) -> void:
	busy(c, 0.8)
	var tt = tg(c, t, 24.0)
	var center = gp(tt.global_position if tt else c.global_position + fwd(c, t) * 10.0)
	paper_storm(hand_pos(c, true), center, 40, 0.35, 0.6, 0.25)
	VFX.shockwave(center + Vector3.UP * 0.1, PAPER, 6.0, 0.4, true)
	for k in 22:
		after(0.2 + k * 0.025, func():
			var a = randf() * TAU
			var r = sqrt(randf()) * 4.5
			var q = gp(center + Vector3(cos(a) * r, 0, sin(a) * r))
			var b = MB.new()
			var h = randf_range(1.8, 3.4)
			b.add("cone", Vector3(0, h * 0.5, 0), Vector3(0.3, h, 0.3), PAPER, Vector3(randf_range(-12, 12), 0, randf_range(-12, 12)), 4)
			for j in 3:
				b.add("box", Vector3(0, h * (0.2 + j * 0.2), 0), Vector3(0.34, 0.01, 0.34), PAPER.darkened(0.12), Vector3(0, j * 30.0, 0))   # kat çizgileri
			var sp = mesh_of(b)
			get_tree().current_scene.add_child(sp)
			sp.global_position = q - Vector3.UP * h
			var tw = sp.create_tween()
			tw.tween_property(sp, "global_position", q, 0.08)
			tw.tween_interval(1.4)
			tw.tween_property(sp, "scale", Vector3(1, 0.05, 1), 0.25)
			tw.tween_callback(sp.queue_free))
	after(0.22, func():
		VFX.star(center + Vector3.UP, PAPER, 2.0)
		Sfx.play("earth", center, 1.6)
		shake(0.4)
		mhit(c, center + Vector3.UP, 4.8, inf(c, "kami_yari", 1.3, {"launch": 10.0, "knock": 3.0, "kind": "heavy", "bleed": 2.0})))


## Kâğıt Tanrının Yolu: gökyüzü ve zemin patlayıcı etiketlerden oluşan bir kâğıt denizine döner, sonra zincirleme dev patlamalar
func p_kami_no_shisha_no_jutsu(c: Node3D, t: Node3D) -> void:
	busy(c, 1.8)
	anim(c, "cast", 0.8)
	var tt = tg(c, t, 40.0)
	var center = gp(tt.global_position if tt else c.global_position + fwd(c, t) * 18.0)
	# zemine yayılan kâğıt denizi (dalgalı kâğıt halısı)
	var sea = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(24, 24)
	pm.subdivide_width = 12; pm.subdivide_depth = 12
	sea.mesh = pm
	sea.material_override = VFX.mat_wind(Color(0.97, 0.96, 0.99), 1.5, 14.0, Vector3(1, 0, 0), 0.9)
	get_tree().current_scene.add_child(sea)
	sea.global_position = center + Vector3.UP * 0.12
	sea.scale = Vector3(0.05, 1, 0.05)
	var tw = sea.create_tween()
	tw.tween_property(sea, "scale", Vector3.ONE, 0.8)
	tw.tween_interval(2.2)
	tw.tween_callback(sea.queue_free)
	for k in 6:
		paper_storm(c.global_position + Vector3.UP * 1.5, center + Vector3(randf_range(-9, 9), 0.5, randf_range(-9, 9)), 25, 0.9, 4.0, 0.4)
	for k in 80:
		after(randf() * 1.4, func():
			var sh = _sheet(0.45)
			get_tree().current_scene.add_child(sh)
			var q = center + Vector3(randf_range(-11, 11), 0, randf_range(-11, 11))
			sh.global_position = q + Vector3.UP * randf_range(12, 20)
			var tw2 = sh.create_tween()
			tw2.tween_property(sh, "global_position", gp(q) + Vector3.UP * 0.2, randf_range(0.8, 1.4))
			tw2.tween_interval(0.6)
			tw2.tween_callback(sh.queue_free))
	Sfx.play("wind", center, 0.6)
	for k in 16:
		after(2.0 + k * 0.08, func():
			var q = gp(center + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10)))
			impact_fx("katon", Color(1, 0.6, 0.2), q + Vector3.UP * 0.5, 1.6)
			if k % 4 == 0:
				shake(1.0)
			hit(c, q + Vector3.UP, 4.5, inf(c, "kami_no_shisha_no_jutsu", 0.55, {"knock": 14.0, "launch": 6.0, "kind": "heavy", "element": "katon"})))


## Kurbağa Yağı Mermisi: ağızdan benekli kalın yağ seli fışkırır; değdiği yerde kaygan yağ gölü
func p_gamayudan(c: Node3D, t: Node3D) -> void:
	busy(c, 0.7)
	var d = fwd(c, t)
	var oil = VFX.mat_water(Color(0.45, 0.32, 0.08), Color(0.78, 0.6, 0.22), Color(0.95, 0.82, 0.4), Vector3(0, 1, 0), 0.95, 0.8, 0.12)
	VFX.gather(_mouth_pos(c), TOAD_OIL, 1.0)
	stream_fx(_mouth_pos(c), (d - Vector3.UP * 0.08).normalized(), 12.0, 1.8, oil, 0.45, func(end):
		VFX.splash(gp(end), 2.2)
		_oil_pool(c, end, 4.5, 8.0))
	Combat.hit_zone(c, c.global_position, d, 12.0, 18.0, 3.0, inf(c, "gamayudan", 0.8, {"knock": 9.0, "kind": "heavy"}))
	Sfx.play("water", c.global_position, 0.7)


## Saç İğneleri: saç diken diken uzar (başın etrafında uzun sivri tutamlar), sonra yüzlerce iğne yağdırır
func p_kebari_senbon(c: Node3D, t: Node3D) -> void:
	busy(c, 1.0)
	var hair: Color = c.model.look.get("hair", Color(0.9, 0.9, 0.88)) if c.get("model") else Color(0.9, 0.9, 0.88)
	var ba = bone_attach(c, "Head")
	if ba:
		var b = MB.new()
		for k in 22:
			var a = deg_to_rad(-100.0 + k * 9.5)
			var e = deg_to_rad(randf_range(-10, 40))
			var dv = Vector3(sin(a) * cos(e), sin(e) + 0.2, -cos(a) * cos(e)).normalized()
			b.add("cone", dv * 0.45, Vector3(0.06, 0.8, 0.06), hair, Vector3(rad_to_deg(acos(clampf(dv.y, -1, 1))), rad_to_deg(atan2(dv.x, dv.z)), 0), 4)
		var spikes = mesh_of(b)
		ba.add_child(spikes)
		spikes.scale = Vector3.ONE * 0.1
		var tw = spikes.create_tween()
		tw.tween_property(spikes, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK)
		tw.tween_interval(0.8)
		tw.tween_property(spikes, "scale", Vector3.ONE * 0.05, 0.2)
		tw.tween_callback(ba.queue_free)
	var d = fwd(c, t)
	var head = c.global_position + Vector3.UP * 1.7
	VFX.shockwave(head, hair.lightened(0.3), 2.5, 0.3, false, d)
	Sfx.play("whoosh", head, 1.7)
	for k in 50:
		after(0.2 + k * 0.012, func():
			var b2 = MB.new()
			b2.add("cyl", Vector3.ZERO, Vector3(0.014, 0.4, 0.014), hair.lightened(0.2), Vector3(90, 0, 0), 4)
			var dir = (d + Vector3(randf_range(-0.3, 0.3), randf_range(-0.12, 0.12), randf_range(-0.3, 0.3))).normalized()
			var pr = shot(c, head + Vector3(randf_range(-0.3, 0.3), randf_range(-0.1, 0.3), randf_range(-0.3, 0.3)), dir, 55.0, mesh_of(b2), inf(c, "kebari_senbon", 0.06, {"knock": 0.5, "kind": "light", "bleed": 1.0}), null, false, 0.6)
			if k % 5 == 0:
				VFX.trail(pr, 0.04, Color(1, 1, 1, 0.8), hair, Color(hair.r, hair.g, hair.b, 0), 8, 0.2))


## Aslan Yelesi: saç dev yeleye döner, onlarca kalın tutam hedefe uzanıp onu kozaya sarar ve sıkar
func p_ranjishigami_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tt = tg(c, t, 14.0)
	busy(c, 1.2)
	if tt == null:
		return
	var hair: Color = c.model.look.get("hair", Color(0.9, 0.9, 0.88)) if c.get("model") else Color(0.9, 0.9, 0.88)
	var hm = StandardMaterial3D.new()
	hm.albedo_color = hair
	for k in 12:
		var off = Vector3(randf_range(-0.5, 0.5), randf_range(0.2, 1.6), randf_range(-0.5, 0.5))
		var wob = randf() * TAU
		tether(func(): return c.global_position + Vector3.UP * 1.75 + Vector3(sin(wob) * 0.2, 0, cos(wob) * 0.2),
			func(): return tt.global_position + off if live(tt) else c.global_position, 0.14, hm, 2.4)
	Sfx.play("whoosh", c.global_position, 0.8)
	after(0.35, func():
		if not live(tt):
			return
		var coc = Node3D.new()
		for j in 5:
			var ring = MeshInstance3D.new()
			var tm = TorusMesh.new()
			tm.inner_radius = 0.42; tm.outer_radius = 0.6; tm.rings = 20; tm.ring_segments = 8
			ring.mesh = tm
			ring.material_override = hm
			ring.position = Vector3.UP * (0.3 + j * 0.35)
			ring.rotation = Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
			coc.add_child(ring)
		tt.add_child(coc)
		coc.scale = Vector3.ONE * 1.6
		var tw = coc.create_tween()
		tw.tween_property(coc, "scale", Vector3.ONE, 0.25)
		tw.tween_interval(2.0)
		tw.tween_callback(coc.queue_free)
		st(tt, "bind", 2.4)
		every(2.0, 0.5, func(_i, _k):
			if live(tt):
				VFX.star(tt.global_position + Vector3.UP, hair.lightened(0.3), 1.0)
				tt.take_hit(inf(c, "ranjishigami_no_jutsu", 0.25, {"knock": 0.0, "kind": "light"})), Callable())
		Combat.popup_text(tt.global_position + Vector3.UP * 2.4, "Yeleye sarıldı!", Color(0.95, 0.9, 0.8)))


## Diken Bekçisi: saç bedeni saran sert dikenli kozaya döner; yaklaşan batar
func p_hari_jizo(c: Node3D, _t: Node3D) -> void:
	busy(c, 0.4)
	var hair: Color = c.model.look.get("hair", Color(0.9, 0.9, 0.88)) if c.get("model") else Color(0.9, 0.9, 0.88)
	var b = MB.new()
	b.add("sphere", Vector3(0, 0.9, 0), Vector3(1.7, 2.0, 1.7), hair.darkened(0.15), Vector3.ZERO, 16)
	for k in 90:
		var a = randf() * TAU
		var e = randf_range(-0.6, 1.3)
		var d = Vector3(cos(a) * cos(e), sin(e), sin(a) * cos(e))
		b.add("cone", Vector3(0, 0.9, 0) + d * 0.85, Vector3(0.09, randf_range(0.45, 0.8), 0.09), hair.lightened(randf() * 0.15), Vector3(rad_to_deg(acos(clampf(d.y, -1, 1))), rad_to_deg(atan2(d.x, d.z)), 0), 4)
	var cocoon = mesh_of(b)
	get_tree().current_scene.add_child(cocoon)
	cocoon.global_position = c.global_position
	cocoon.scale = Vector3.ONE * 0.1
	cocoon.create_tween().tween_property(cocoon, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	VFX.shockwave(c.global_position + Vector3.UP, hair, 4.0, 0.3, false)
	VFX.smoke_ring(gp(c.global_position) + Vector3.UP * 0.1, 3.0, Color(0.7, 0.65, 0.6))
	if c is Player:
		Buffs.add("hari_jizo", 4.0, {"armor": 0.1, "_name": "Diken Bekçisi"})
	every(4.0, 0.25, func(_i, _k):
		if is_instance_valid(cocoon) and live(c):
			cocoon.global_position = c.global_position
			for e in mhit(c, c.global_position + Vector3.UP, 2.2, inf(c, "hari_jizo", 0.15, {"knock": 6.0, "kind": "light", "bleed": 1.0})):
				pass, func():
		if is_instance_valid(cocoon):
			cocoon.queue_free())


## Kurbağa Midesi Bağı: çevre dev bir kurbağanın etli, kıvrımlı mide tüneline döner — içindekiler yapışıp erir
func p_kuchiyose_gamaguchi_shibari(c: Node3D, t: Node3D) -> void:
	busy(c, 1.0)
	var tt = tg(c, t, 16.0)
	var center = gp(tt.global_position if tt else c.global_position + fwd(c, t) * 6.0)
	summon_circle(c.global_position, 2.0, Color(1, 0.55, 0.15), 0.8)
	var flesh = VFX.mat_water(Color(0.45, 0.08, 0.12), Color(0.78, 0.3, 0.35), Color(0.95, 0.6, 0.62), Vector3(0, 1, 0), 1.0, 0.25, 0.05)
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = center
	var tube = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 6.0; cm.bottom_radius = 7.0; cm.height = 7.0; cm.radial_segments = 28; cm.rings = 8
	cm.flip_faces = true
	tube.mesh = cm
	tube.material_override = flesh
	tube.position = Vector3.UP * 3.0
	root.add_child(tube)
	for k in 10:   # kıvrımlı et katmanları
		var fold = MeshInstance3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = 5.6 + (k % 2) * 0.3; tm.outer_radius = 7.2; tm.rings = 28; tm.ring_segments = 8
		fold.mesh = tm
		fold.material_override = flesh
		fold.position = Vector3.UP * (0.3 + k * 0.65)
		fold.scale = Vector3(1, 0.35, 1)
		root.add_child(fold)
	var floor_m = MeshInstance3D.new()
	var fm = CylinderMesh.new()
	fm.top_radius = 7.0; fm.bottom_radius = 7.0; fm.height = 0.1; fm.radial_segments = 28
	floor_m.mesh = fm
	floor_m.material_override = flesh
	root.add_child(floor_m)
	root.scale = Vector3(1, 0.05, 1)
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(5.5)
	tw.tween_property(root, "scale", Vector3(1, 0.05, 1), 0.4)
	tw.tween_callback(root.queue_free)
	shake(0.5)
	Sfx.play("water", center, 0.5)
	every(6.0, 0.5, func(_i, _k):
		for e in enemies_near(c, center, 7.0):
			st(e, "bind", 0.6)
			VFX.puffs(e.global_position + Vector3.UP * 0.3, {"amount": 6, "life": 0.6, "size": 0.4, "radius": 0.4, "vmin": 0.5, "vmax": 1.5, "dir": Vector3.UP, "spread": 40.0, "add": false,
				"colors": [Color(0.8, 0.9, 0.4, 0.7), Color(0.7, 0.8, 0.3, 0)]})
			e.take_hit(inf(c, "kuchiyose_gamaguchi_shibari", 0.12, {"knock": 0.0, "kind": "light"})), Callable())


## Kurbağa Yağı Alev Bombası: yanında kurbağa belirir, benekli yağ seli fışkırtır; sen ateş üflersin — yağla büyüyen dev alev seli, yanan göl
func p_katon_gamayu_endan(c: Node3D, t: Node3D) -> void:
	busy(c, 1.5)
	var d = fwd(c, t)
	var side = d.cross(Vector3.UP).normalized()
	var toad_at = gp(c.global_position + side * 1.8)
	summon_circle(toad_at, 1.2, Color(1, 0.55, 0.15), 0.5)
	FX.smoke_puff(toad_at + Vector3.UP * 0.6, 1.2, 16)
	var toad = mesh_of(_elder_toad(false))
	get_tree().current_scene.add_child(toad)
	toad.global_position = toad_at
	toad.scale = Vector3.ONE * 4.5
	toad.rotation.y = atan2(d.x, d.z)
	var oil = VFX.mat_water(Color(0.45, 0.32, 0.08), Color(0.78, 0.6, 0.22), Color(0.95, 0.82, 0.4), Vector3(0, 1, 0), 0.95, 0.8, 0.12)
	after(0.4, func():
		stream_fx(toad_at + Vector3.UP * 0.9 + d * 0.6, (d - Vector3.UP * 0.04).normalized(), 14.0, 1.6, oil, 0.5)
		Sfx.play("water", toad_at, 0.6))
	after(0.7, func():
		if not live(c):
			return
		anim(c, "push", 1.2)
		fire_stream(_mouth_pos(c), (d - Vector3.UP * 0.05).normalized(), 24.0, 5.5, 12)
		after(0.5, func(): impact_fx("katon", Color(1, 0.5, 0.1), gp(c.global_position + d * 22.0) + Vector3.UP, 2.0))
		VFX.embers(c.global_position + Vector3.UP * 1.4 + d * 4.0, Color(1, 0.55, 0.1), 60, 16.0)
		Sfx.play("fire", c.global_position, 0.6)
		Combat.hit_zone(c, c.global_position, d, 24.0, 26.0, 4.0, inf(c, "katon_gamayu_endan", 1.6, {"element": "katon", "burn": 3.0, "knock": 8.0, "kind": "heavy"}))
		var pool_at = gp(c.global_position + d * 12.0)
		VFX.linger(pool_at, "katon", Color(1, 0.5, 0.1), 2.5, 5.0)
		every(5.0, 0.5, func(_i, _k):
			for e in enemies_near(c, pool_at, 4.0):
				e.take_hit(inf(c, "katon_gamayu_endan", 0.12, {"element": "katon", "burn": 1.0, "knock": 0.0, "kind": "light"})), Callable())
		shake(0.8))
	after(1.8, func():
		if is_instance_valid(toad):
			FX.smoke_puff(toad.global_position + Vector3.UP * 0.6, 1.2, 14)
			toad.queue_free())


## Bilge Sanatı: Kurbağa Çağrısı — omuzlardaki iki bilge kurbağa birlikte öter; turuncu ses halkaları yayılır, duyan herkes donar
func p_senpo_kawazu_naki(c: Node3D, _t: Node3D) -> void:
	busy(c, 1.6)
	anim(c, "cast", 0.8)
	var elders = []
	var m = c.get("model")
	if m and m.skel:
		var sk: Skeleton3D = m.skel
		var chest_b = "UpperChest" if sk.find_bone("UpperChest") >= 0 else "Chest"
		for sx in [-1.0, 1.0]:
			var ua = "LeftUpperArm" if sx > 0 else "RightUpperArm"
			var sh_b = "LeftShoulder" if sx > 0 else "RightShoulder"
			if sk.find_bone(sh_b) < 0:
				sh_b = chest_b
			var p_ua: Vector3 = m._grest(sk.find_bone(ua)).origin
			var seat = p_ua + Vector3(sx * 0.035, 0.035, -0.01)
			var ba = m._attach(sh_b, Transform3D(Basis.IDENTITY, seat))
			var mi = mesh_of(_elder_toad(sx < 0))
			ba.get_child(0).add_child(mi)
			mi.scale = Vector3.ONE * 0.05
			mi.create_tween().tween_property(mi, "scale", Vector3.ONE * 0.62, 0.3).set_trans(Tween.TRANS_BACK)
			FX.smoke_puff(c.global_position + Vector3.UP * 1.6 + c.face_dir().cross(Vector3.UP) * -sx * 0.2, 0.3, 6)
			elders.append(ba)
	Sfx.play("genjutsu", c.global_position, 0.5)
	for k in 6:
		after(0.4 + k * 0.18, func():
			if live(c):
				VFX.shockwave(c.global_position + Vector3.UP * 1.6, SAGE, 6.0 + k * 5.0, 0.6, false)
				VFX.shockwave(c.global_position + Vector3.UP * 0.1, SAGE, 6.0 + k * 5.0, 0.6, true))
	after(1.2, func():
		for e in enemies_near(c, c.global_position, 26.0):
			st(e, "stun", 6.0)
			VFX.star(e.global_position + Vector3.UP * 1.6, SAGE, 1.2)
			Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Kurbağa şarkısı!", SAGE))
	after(6.0, func():
		for ba in elders:
			if is_instance_valid(ba):
				ba.queue_free())


## Alev seli: ağızdan büyüyerek ilerleyen katmanlı alev küreleri zinciri (gerçek alev shader'ı), kor ve duman
func fire_stream(from: Vector3, d: Vector3, length: float, max_size: float, n: int) -> void:
	for k in n:
		after(k * 0.035, func():
			var fb = VFX.fireball(0.8 + max_size * float(k) / n)
			get_tree().current_scene.add_child(fb)
			fb.global_position = from
			var end = from + d * (length * (0.35 + 0.65 * float(k) / n))
			var tw = fb.create_tween()
			tw.tween_property(fb, "global_position", end, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(fb, "scale", Vector3.ONE * 1.3, 0.35)
			tw.tween_property(fb, "scale", Vector3.ONE * 0.05, 0.35)
			tw.tween_callback(fb.queue_free)
			VFX.puffs(end, {"amount": 8, "life": 0.9, "size": 1.2 + k * 0.2, "radius": 0.8, "vmin": 1, "vmax": 3, "dir": Vector3.UP, "spread": 40.0, "add": false,
				"colors": [Color(0.35, 0.25, 0.2, 0.6), Color(0.25, 0.2, 0.18, 0)]}))
	VFX.embers(from + d * length * 0.4, Color(1, 0.55, 0.1), 50, 14.0)
