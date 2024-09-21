local L = LibStub("AceLocale-3.0"):NewLocale("NameplateCCnTrinket", "koKR")
if not L then
  return
end

L["Show Friendly Player"] = "우호적 플레이어 표시"
L["CC Common Icon"] = "CC 공통 아이콘"
L["CC Show Monster"] = "몬스터에도 CC 점감 표시"
L["FrameSize"] = "아이콘 크기"
L["Left Frame X"] = true
L["Right Frame X"] = true
L["Y"] = true
L["TargetAlpha"] = "대상 / 주시 불투명도"
L["OtherAlpha"] = "비대상 불투명도"
L["/NCT\n/NameplateCCnTrinket\n"] = true
L["Version"] = "버전"
L["Author"] = "제작자"
L["Test"] = "테스트"
L["Category"] = "CC 분류"
L["taunt"] = "도발"
L["incapacitate"] = "행동 불가"
L["silence"] = "침묵"
L["disorient"] = "공포"
L["stun"] = "스턴"
L["root"] = "묶기"
L["knockback"] = "밀려남"
L["disarm"] = "무장 해제"
L["Category Desc"] =
  "도발과 밀려남 카테고리는 아직 올바르게 동작하지 않습니다.(나머지와 동작 방식이 다름)\n"
L["selectnameplate"] = "|c00008000" .. "NameplateCCnTrinket" .. " |r " .. "테스트 할 이름표를 선택하세요"
L["Test Desc"] = "먼저 이름표를 선택한 후 테스트 버튼을 누르세요"
L["Show Friendly Player Desc"] = "우호적 플레이어에도 표시"
L["CC Common Icon Desc"] = "CC 분류별 공통 아이콘으로 표시"
L["CC Show Monster Desc"] = "몬스터에도 CC 점감 표시"
L["FrameSize Desc"] = "아이콘 크기 변경(20 ~ 30을 추천)"
L["Left X Desc"] = "왼쪽 프레임 좌우 조절"
L["Right X Desc"] = "오른쪽 프레임 좌우 조절"
L["Y Desc"] = "상하 조절"
L["TargetAlpha Desc"] = "대상의 불투명도"
L["OtherAlpha Desc"] = "비대상의 불투명도"
L["taunt Desc"] = "도발, 어둠의 명령 등.."
L["incapacitate Desc"] = "양, 사술 등.."
L["silence Desc"] = "목조르기, 침묵 등.."
L["disorient Desc"] = "공포, 회오리 바람 등.."
L["stun Desc"] = "급소 가격, 폭풍망치 등.."
L["root Desc"] = "얼음 회오리, 뿌리 묶기 등.."
L["knockback Desc"] = "고어핀드의 손아귀, 태풍 등.."
L["disarm Desc"] = "무장 해제, 장비 분해 등.."

L["Function"] = "기능"
L["Interrupt"] = "차단기"
L["Interrupt Desc"] = "차단기 쿨다운 표시 On / Off "
L["Racial"] = "종족 특성"
L["Racial Desc"] = "종족 특성 쿨다운 표시 On / Off"
L["Trinket"] = "계급장"
L["Trinket Desc"] = "계급장 쿨다운 표시 On / Off"
L["CC"] = "CC 점감"
L["CC Desc"] = "CC 점감 표시 On / Off"
L["Dispel"] = "해제기"
L["Dispel Desc"] = "해제기 쿨다운 표시 On / Off"
L["CurrentTime"] = "CC Highlight"
L["CurrentTime Desc"] = "CC 지속시간 동안 하이라이트 효과 부여"

L["OtherScale"] = "비대상 프레임 비율"
L["OtherScale Desc"] = "비대상 프레임의 상대적 비율(대상, 주시 대상 제외)"
L["CooldownSpiral"] = "쿨다운 애니메이션"
L["CooldownSpiral Desc"] = "쿨다운 애니메이션 표시"

L["pSetting"] = "본인 점감"
L["pSetting Desc"] =
  "본인 점감 프레임 설정(이 기능을 사용 하려면 Settings의 [우호적 플레이어 표시] 옵션이 켜져 있어야합니다.)\n"
L["Enable"] = "활성화"
L["Enable Desc"] = "사용할지 여부"
L["pxOfs"] = "X"
L["pxOfs Desc"] = "좌 / 우 이동 "
L["pyOfs"] = "Y"
L["pyOfs Desc"] = "상 / 하 이동"
L["pScale"] = "비율"
L["pScale Desc"] = "Nameplate옆에 붙는 프레임을 1로 기준했을때 상대적 비율 "
L["attachFrame"] = "Relative Frame"
L["attachFrame Desc"] = "이 프레임이 붙을 프레임"
L["rightframe"] = " 올바른 프레임명을 입력하세요"

L["CCHL Desc"] = "CC 지속시간 동안 하이라이트 효과 부여"
L["CCHL Enable"] = "하이라이트 활성화"
L["CCHL Style"] = "하이라이트 스타일"
L["CCHL pixellength"] = "선의 길이"
L["CCHL pixelth"] = "선의 두께"
L["CCHL autoscale"] = "입자 스케일"
L["ColorBasc"] = "기본 아이콘 색"
L["ColorFull"] = "100% 점감 색"
L["ColorHalf"] = "50% 점감 색"
L["ColorQuat"] = "25% 점감 색"
L["Func_IconBorder"] = "아이콘 가장자리 두께"

L["Func_FontEnable"] = "쿨다운 숫자 사용하기"
L["Func_FontScale"] = "쿨다운 숫자 크기 비율"
L["Func_FontPoint"] = "쿨다운 숫자 위치"
L["TOP"] = "위"
L["TOPLEFT"] = "좌측 위"
L["TOPRIGHT"] = "우측 위"
L["RIGHT"] = "우측"
L["CENTER"] = "중앙"
L["LEFT"] = "좌측"
L["BOTTOMRIGHT"] = "우측 아래"
L["BOTTOMLEFT"] = "좌측 아래"
L["BOTTOM"] = "아래"

L["DRList-1.0"] = "DRList-1.0"
L["rightcommon"] = " 존재하는 SpellID를 입력해주세요"

L["taunt name"] = "도발 공통 아이콘"
L["taunt Common Desc"] = "Default 355"
L["incapacitate name"] = "행동불가 공통 아이콘"
L["incapacitate Common Desc"] = "Default 118"
L["silence name"] = "침묵 공통 아이콘"
L["silence Common Desc"] = "Default 15487"
L["disorient name"] = "공포 공통 아이콘"
L["disorient Common Desc"] = "Default 118699"
L["stun name"] = "스턴 공통 아이콘"
L["stun Common Desc"] = "Default 408"
L["root name"] = "묶기 공통 아이콘"
L["root Common Desc"] = "Default 122"
L["knockback name"] = "밀려남 공통 아이콘"
L["knockback Common Desc"] = "Default 132469"
L["disarm name"] = "무장해제 공통 아이콘"
L["disarm Common Desc"] = "Default 236077"

L["SortingStyle"] = "Right Frame 스타일"
L["SortingStyle Desc"] = "격자 또는 직선 스타일"
