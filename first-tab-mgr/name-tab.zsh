tab=mgr
vared -p "First tab: " tab
[[ -n $tab && $tab != mgr ]] && "$HERDR" tab rename "$FIRST_TAB_ID" "$tab" >/dev/null
