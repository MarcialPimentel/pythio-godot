#!/usr/bin/env bash
# Builds every sound in assets/audio/sfx/ from the CC0 Kenney packs on Marz's PC plus
# code-made tones (ffmpeg). Re-run it after changing a recipe; it overwrites the .ogg files.
#   bash tools/audio/build_sfx.sh            (all sounds)
#   bash tools/audio/build_sfx.sh combo      (just one)
# Needs ffmpeg. What each sound is made of: docs/sound-design.md.
set -euo pipefail
LIB=${LIB:-/c/Users/marci/Documents/GameDev/_audio/kenney}
OUT=$(cd "$(dirname "$0")/../.." && pwd)/assets/audio/sfx
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
ONLY=${1:-}
R=44100
FF="ffmpeg -v error -y"

imp() { echo "$LIB/impact-sounds/Audio/$1.ogg"; }
ui()  { echo "$LIB/interface-sounds/Audio/$1.ogg"; }
rpg() { echo "$LIB/rpg-audio/Audio/$1.ogg"; }

# rec OUT IN [extra filters]: mono, leading silence trimmed, optional filters (pitch, trim...)
rec() {
	local f="silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.002"
	[ -n "${3:-}" ] && f="$f,$3"
	$FF -i "$2" -af "$f" -ac 1 -ar $R "$TMP/$1.wav"
}
# slow OUT IN FACTOR [extra]: tape-style pitch+speed (0.8 = lower, heavier, longer)
slow() { rec "$1" "$2" "asetrate=$R*$3,aresample=$R${4:+,$4}"; }
# gen OUT SECONDS EXPR [extra filters]: a code-made tone
gen() { $FF -f lavfi -i "aevalsrc='$3':s=$R:d=$2" ${4:+-af "$4"} -ac 1 "$TMP/$1.wav"; }
# noise OUT SECONDS COLOR FILTERS: filtered noise
noise() { $FF -f lavfi -i "anoisesrc=c=$3:d=$2:a=0.7:r=$R" -af "$4" -ac 1 "$TMP/$1.wav"; }
# mix OUT part:delay_ms:gain_db ...
mix() {
	local out=$1; shift
	local ins="" fc="" tags="" i=0
	for p in "$@"; do
		IFS=: read -r name delay gain <<<"$p"
		ins="$ins -i $TMP/$name.wav"
		fc="$fc[$i]adelay=delays=${delay}:all=1,volume=${gain}dB[a$i];"
		tags="$tags[a$i]"
		i=$((i + 1))
	done
	$FF $ins -filter_complex "${fc}${tags}amix=inputs=$i:normalize=0:duration=longest" -ac 1 "$TMP/$out.wav"
}
# final NAME SRC RMS_DB MAX_SECONDS FADE_SECONDS: cut, fade, set loudness (peak capped at -3 dB), save .ogg
final() {
	local name=$1 src=$TMP/$2.wav rms=$3 len=$4 fade=$5
	$FF -i "$src" -af "atrim=0:$len,afade=t=out:st=$(echo "$len $fade" | awk '{print $1-$2}'):d=$fade" "$TMP/_cut.wav"
	local stats mean peak gain
	stats=$(ffmpeg -hide_banner -i "$TMP/_cut.wav" -af volumedetect -f null - 2>&1)
	mean=$(echo "$stats" | sed -n 's/.*mean_volume: \(-*[0-9.]*\) dB/\1/p')
	peak=$(echo "$stats" | sed -n 's/.*max_volume: \(-*[0-9.]*\) dB/\1/p')
	gain=$(awk -v m="$mean" -v p="$peak" -v t="$rms" 'BEGIN{g=t-m; c=-3-p; if (c<g) g=c; print g}')
	$FF -i "$TMP/_cut.wav" -af "volume=${gain}dB" -ac 1 -ar $R -c:a libvorbis -q:a 4 "$OUT/$name.ogg"
	echo "$name  gain ${gain} dB"
}
want() { [ -z "$ONLY" ] || [ "$ONLY" = "$1" ]; }

# Shared pieces
thump() { gen "$1" 0.35 "sin(2*PI*($2*t+90*(1-exp(-t*16))/16))*exp(-t*12)"; }
bell()  { gen "$1" "$3" "min(1,t*400)*(sin(2*PI*$2*t)+0.45*sin(2*PI*$2*2.01*t)*exp(-t*4)+0.2*sin(2*PI*$2*3.02*t)*exp(-t*8))*exp(-t*$4)*0.4"; }

# ── Your spells (one sound per spell category) ────────────────
if want cast_land || want cast_other; then
	thump w_thump 60
	noise w_air 0.3 pink "bandpass=f=900:width_type=h:w=800,afade=t=out:st=0.02:d=0.25"
	gen w_shine 0.4 "min(1,t*60)*sin(2*PI*1175*t)*exp(-t*9)*0.25"
	mix whump w_thump:0:-4 w_air:0:0 w_shine:10:-2
	final cast_land whump -22 0.4 0.15
	final cast_other whump -22 0.4 0.15
fi
if want cast_heal; then   # warm two-note chime, a fifth apart, with a soft glass sparkle
	gen h1 0.7 "min(1,t*200)*(sin(2*PI*523.25*t)+0.25*sin(2*PI*1046.5*t))*exp(-t*7)*0.4"
	gen h2 0.7 "min(1,t*200)*(sin(2*PI*783.99*t)+0.2*sin(2*PI*1568*t))*exp(-t*6)*0.4"
	rec h_glass "$(ui glass_002)"
	mix heal h1:0:0 h2:70:0 h_glass:0:-16
	final cast_heal heal -21 0.6 0.2
fi
if want cast_hot; then    # rising shimmer over a leaf-like rustle
	gen hot_sh 0.55 "min(1,t*40)*exp(-t*2.5)*(0.7+0.3*sin(2*PI*18*t))*(sin(2*PI*(660*t+330*t*t))+0.4*sin(2*PI*(990*t+495*t*t)))*0.35"
	rec hot_cloth "$(rpg cloth1)" "atrim=0:0.5"
	mix hot hot_sh:0:0 hot_cloth:0:6
	final cast_hot hot -22 0.55 0.15
fi
if want cast_shield; then # glass tap plus a ringing glass hum
	rec sh_glass "$(imp impactGlass_light_002)"
	gen sh_ring 0.5 "min(1,t*400)*(sin(2*PI*1760*t)+0.5*sin(2*PI*2640*t)+0.25*sin(2*PI*4180*t)*exp(-t*10))*exp(-t*7)*0.3"
	mix shield sh_glass:0:0 sh_ring:0:-3
	final cast_shield shield -21 0.5 0.15
fi
if want cast_mitigate; then # heavy plate, lowered, with a low gong under it
	slow mi_plate "$(imp impactPlate_heavy_001)" 0.8
	gen mi_gong 0.65 "min(1,t*150)*(sin(2*PI*130*t)+0.6*sin(2*PI*358.8*t)+0.3*sin(2*PI*702*t)*exp(-t*6))*exp(-t*5)*0.4"
	mix mitigate mi_plate:0:0 mi_gong:0:-2
	final cast_mitigate mitigate -21 0.6 0.2
fi
if want cast_start; then  # short soft charge-up
	gen start 0.28 "pow(sin(PI*t/0.28),2)*(0.75+0.25*sin(2*PI*24*t))*(sin(2*PI*(330*t+600*t*t))+0.4*sin(2*PI*(495*t+900*t*t)))*0.3"
	final cast_start start -27 0.28 0.06
fi
if want cant_cast; then   # dull wooden click, lowered and muffled
	slow cant "$(imp impactWood_light_001)" 0.8 "lowpass=f=1500"
	final cant_cast cant -26 0.15 0.05
fi
if want low_mana; then    # hollow tone sliding down an octave
	gen lowm 0.55 "min(1,t*80)*exp(-t*3)*(sin(2*PI*(440*t-220*t*t))+0.33*sin(3*2*PI*(440*t-220*t*t)))*0.4" "lowpass=f=2000"
	final low_mana lowm -23 0.55 0.15
fi

# ── Combos and passives ──────────────────────────────────────
if want combo; then       # coin clink + jingle + a bright two-note bell (gold)
	rec c_clink "$(imp impactMetal_light_001)"
	rec c_coins "$(rpg handleCoins)" "atrim=0:0.6"
	bell c_b1 1318.5 0.8 5
	bell c_b2 1975.5 0.8 5
	mix combo c_clink:0:-3 c_coins:20:2 c_b1:0:0 c_b2:80:-1
	final combo combo -18 0.75 0.25
fi
if want passive_proc; then # smaller cousin: one clink, one small bell
	rec p_clink "$(imp impactMetal_light_004)"
	bell p_b 1568 0.35 9
	mix passive p_clink:0:-6 p_b:0:0
	final passive_proc passive -23 0.3 0.1
fi

# ── Danger ───────────────────────────────────────────────────
if want burst_warning; then # low drum, then a blade drawn
	thump bw_drum 48
	rec bw_knife "$(rpg drawKnife2)"
	mix warn bw_drum:0:-3 bw_knife:60:16
	final burst_warning warn -19 0.65 0.15
fi
if want burst_hit; then   # heavy punch with a short blade bite
	rec bh_punch "$(imp impactPunch_heavy_002)"
	rec bh_slice "$(rpg knifeSlice2)" "atrim=0:0.2,afade=t=out:st=0.1:d=0.1"
	mix hit bh_punch:0:0 bh_slice:0:-9
	final burst_hit hit -16 0.4 0.12
fi
if want shield_absorb; then # plate clang: you saved him
	rec sa_plate "$(imp impactPlate_light_000)"
	rec sa_metal "$(imp impactMetal_medium_000)"
	mix absorb sa_plate:0:0 sa_metal:0:-3
	final shield_absorb absorb -18 0.45 0.15
fi
if want shield_break; then  # glass shattering
	rec sb_heavy "$(imp impactGlass_heavy_001)"
	rec sb_light "$(imp impactGlass_light_001)"
	mix shbreak sb_heavy:0:0 sb_light:30:-6
	final shield_break shbreak -18 0.45 0.12
fi
if want baron_phase; then   # lowered bell over a deep drum
	slow bp_bell "$(imp impactBell_heavy_002)" 0.7
	thump bp_drum 42
	mix phase bp_bell:0:0 bp_drum:0:-3
	final baron_phase phase -18 1.0 0.3
fi
if want fighter_death; then # body falls, armour hits stone
	rec fd_body "$(imp impactSoft_heavy_000)"
	slow fd_plate "$(imp impactPlate_heavy_004)" 0.85
	mix death fd_body:0:0 fd_plate:90:-3
	final fighter_death death -16 1.0 0.35
fi

# ── Debuffs, Cleanse, Bandage ────────────────────────────────
if want debuff; then        # a short hiss
	noise d_hiss 0.45 pink "highpass=f=2500,lowpass=f=7000,afade=t=in:d=0.04,afade=t=out:st=0.12:d=0.3"
	final debuff d_hiss -23 0.4 0.1
fi
if want debuff_poison; then # rising bubbles over a sickly hiss
	gen po_bub 0.45 "st(0,mod(t,0.065));sin(2*PI*(350*ld(0)+8000*ld(0)*ld(0))*(1+0.25*sin(t*37)))*exp(-ld(0)*55)*0.5"
	noise po_hiss 0.45 pink "bandpass=f=1500:width_type=h:w=1500,afade=t=in:d=0.05,afade=t=out:st=0.15:d=0.3"
	mix poison po_bub:0:0 po_hiss:0:-8
	final debuff_poison poison -22 0.42 0.12
fi
if want debuff_bleed; then  # a cut, then two drips
	rec bl_cut "$(rpg knifeSlice2)" "atrim=0:0.24,afade=t=out:st=0.14:d=0.1"
	gen bl_drip 0.08 "sin(2*PI*(900*t+12000*t*t))*exp(-t*70)*0.6"
	mix bleed bl_cut:0:0 bl_drip:290:-4 bl_drip:430:-8
	final debuff_bleed bleed -18 0.5 0.06
fi
if want debuff_hex; then    # breathy whisper over a low drone
	noise hx_w1 0.55 pink "bandpass=f=1100:width_type=h:w=900,tremolo=f=7:d=0.7,afade=t=in:d=0.06,afade=t=out:st=0.25:d=0.3"
	noise hx_w2 0.55 white "bandpass=f=2600:width_type=h:w=1200,tremolo=f=7:d=0.7,afade=t=in:d=0.06,afade=t=out:st=0.25:d=0.3"
	gen hx_drone 0.55 "min(1,t*10)*(sin(2*PI*73*t)*0.3+sin(2*PI*146*t)*0.15+sin(2*PI*219.5*t)*0.08)" "afade=t=out:st=0.25:d=0.3"
	mix hex hx_w1:0:0 hx_w2:0:-8 hx_drone:0:-2
	final debuff_hex hex -22 0.55 0.15
fi
heart() { gen "$1" 0.25 "sin(2*PI*(42*t+60*(1-exp(-t*20))/20))*exp(-t*18)+0.25*sin(2*PI*(126*t))*exp(-t*30)"; }
if want debuff_dread; then  # heartbeat over a beating low drone
	heart dr_beat
	gen dr_drone 0.85 "min(1,t*6)*(sin(2*PI*55*t)+0.6*sin(2*PI*55.8*t)+0.35*sin(2*PI*165.5*t)+0.2*sin(2*PI*220*t))*0.25" "afade=t=out:st=0.5:d=0.35"
	mix dread dr_beat:0:0 dr_beat:170:-4 dr_drone:0:-3
	final debuff_dread dread -20 0.85 0.25
fi
if want dread_kill; then    # a heartbeat that slows, weakens and stops
	heart dk_beat
	gen dk_drone 1.1 "min(1,t*6)*(sin(2*PI*55*t)+0.6*sin(2*PI*55.8*t)+0.2*sin(2*PI*220*t))*0.25" "afade=t=out:st=0.4:d=0.7"
	mix dkill dk_beat:0:0 dk_beat:170:-4 dk_beat:620:-7 dk_beat:790:-12 dk_drone:0:-5
	final dread_kill dkill -19 1.1 0.3
fi
if want cleanse; then       # airy whoosh with a faint high chime
	noise cl_air 0.45 white "bandpass=f=2500:width_type=h:w=2000,afade=t=in:d=0.05,afade=t=out:st=0.12:d=0.3"
	gen cl_chime 0.35 "min(1,t*300)*(sin(2*PI*1568*t)+0.6*sin(2*PI*2093*t))*exp(-t*8)*0.25"
	mix cleanse cl_air:0:0 cl_chime:150:-6
	final cleanse cleanse -21 0.45 0.12
fi
if want bandage; then       # cloth torn, then wrapped
	noise ba_tear 0.15 pink "bandpass=f=1800:width_type=h:w=1200,afade=t=out:st=0.03:d=0.12"
	rec ba_cloth "$(rpg cloth1)" "atrim=0:0.5"
	mix bandage ba_tear:0:0 ba_cloth:100:8
	final bandage bandage -22 0.6 0.15
fi

# ── Round flow ───────────────────────────────────────────────
if want round_start; then   # a low bell stinger
	slow rs_bell "$(imp impactBell_heavy_002)" 0.85
	final round_start rs_bell -20 0.85 0.3
fi
if want baron_arrive; then  # a heavy door slam and a deep bell
	rec ba_door "$(rpg doorClose_3)"
	slow ba_bell "$(imp impactBell_heavy_000)" 0.6
	mix baron ba_door:0:0 ba_bell:60:0
	final baron_arrive baron -18 1.8 0.6
fi
if want job_finished; then  # coins, then a register-like ding
	rec jf_coins "$(rpg handleCoins)" "silenceremove=start_periods=1:start_threshold=-20dB"
	bell jf_ding 1568 1.0 4
	mix job jf_coins:0:0 jf_ding:220:-8
	final job_finished job -19 1.3 0.4
fi
if want countdown_tick; then # a dry wooden knock
	rec ct "$(imp impactWood_light_003)"
	final countdown_tick ct -29 0.12 0.04
fi
if want pick_screen; then   # a page flicked and a card set down
	rec ps_flip "$(rpg bookFlip3)"
	rec ps_place "$(rpg bookPlace3)"
	mix pick ps_flip:0:4 ps_place:60:-3
	final pick_screen pick -22 0.4 0.12
fi
if want bounty; then        # a heavy purse set on a table
	rec bo_place "$(rpg bookPlace1)"
	rec bo_coins "$(rpg handleCoins)"
	slow bo_thud "$(imp impactSoft_heavy_002)" 0.9
	mix bounty bo_place:0:0 bo_thud:0:-6 bo_coins:40:0
	final bounty bounty -20 1.0 0.3
fi
if want game_over; then     # a slow, low toll
	slow go_bell "$(imp impactBell_heavy_001)" 0.55
	final game_over go_bell -20 3.0 0.9
fi
