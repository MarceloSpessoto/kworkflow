#!/bin/bash
#
include './src/lib/dialog_ui.sh'
include './tests/utils.sh'

function setUp()
{
  export ORIGINAL_PATH="$PWD"
  export TMP_DIR="${SHUNIT_TMPDIR}/ui"
  export KW_ETC_DIR="${TMP_DIR}"

  alias tput='tput_mock'
  [[ "$TERM" == '' || "$TERM" == 'dumb' ]] && TPUTTERM=' -T xterm-256color'

  EXPECTED_DEFAULT_WIDTH=$(eval tput"${TPUTTERM}" cols)
  EXPECTED_DEFAULT_HEIGHT=$(eval tput"${TPUTTERM}" lines)

  mkdir -p "$TMP_DIR"
  mkdir -p "$KW_ETC_DIR"
  # Let's run all test in a well-contained folder
  cd "${TMP_DIR}" || {
    fail "($LINENO): setUp: It was not possible to move into ${TMP_DIR}"
  }
}

function tearDown()
{
  cd "$ORIGINAL_PATH" || {
    fail "($LINENO): tearDown: It was not possible to move into ${ORIGINAL_PATH}"
    return
  }

  DIALOG_LAYOUT=''
  rm -rf "$SHUNIT_TMPDIR"
}

function test_ui_setup_no_layout()
{
  ui_setup

  assert_equals_helper 'Expected height' "$LINENO" "$EXPECTED_DEFAULT_HEIGHT" "$DEFAULT_HEIGHT"
  assert_equals_helper 'Expected width' "$LINENO" "$EXPECTED_DEFAULT_WIDTH" "$DEFAULT_WIDTH"
  assert_equals_helper 'Expected no layout' "$LINENO" '' "$DIALOG_LAYOUT"
}

function test_ui_setup_with_layout()
{
  # create a fake default layout
  mkdir -p "${KW_ETC_DIR}/dialog_ui/"
  touch "${KW_ETC_DIR}/dialog_ui/lala"

  ui_setup 'lala'

  assert_equals_helper 'Expected no layout' "$LINENO" "${KW_ETC_DIR}/dialog_ui/lala" "$DIALOG_LAYOUT"
}

function test_create_menu_options_rely_on_some_default_options()
{
  local menu_title='kunit test inside kw'
  local menu_message_box='This should be a useful message box'
  local -a menu_list_string_array=("I'm number 1" "I'm number 2")
  local expected_cmd="dialog --backtitle \$'${KW_UPSTREAM_TITLE}'"
  local output

  expected_cmd+=" --title $'${menu_title}' --clear --colors --cancel-label $'Exit' --menu $'${menu_message_box}'"
  expected_cmd+=" '${EXPECTED_DEFAULT_HEIGHT}' '${EXPECTED_DEFAULT_WIDTH}' '0'"
  expected_cmd+=" '1' $'I\'m number 1' '2' $'I\'m number 2'"

  output=$(create_menu_options "$menu_title" "$menu_message_box" menu_list_string_array '' '' '' '' '' '' 'TEST_MODE')
  assert_equals_helper 'Expected simple dialog menu' "$LINENO" "${output}" "${expected_cmd}"
}

function test_create_menu_options_use_all_options()
{
  local menu_title='kunit test inside kw'
  local menu_message_box='This should be a useful message box'
  local -a menu_list_string_array=("I'm number 1" "I'm number 2")
  local expected_cmd="dialog --backtitle \$'${KW_UPSTREAM_TITLE}'"
  local output

  expected_cmd+=" --title $'${menu_title}' --clear --colors --cancel-label $'Xpto'"
  expected_cmd+=" --extra-button --extra-label 'Return' --menu $'${menu_message_box}'"
  expected_cmd+=" '300' '300' '1'"
  expected_cmd+=" $'I\'m number 1' '' $'I\'m number 2' ''"

  output=$(create_menu_options "$menu_title" "$menu_message_box" menu_list_string_array 1 'Xpto' '300' '300' '1' '1' 'TEST_MODE')
  assert_equals_helper 'Expected custom dialog menu' "$LINENO" "${output}" "${expected_cmd}"
}

function test_create_simple_checklist_rely_on_some_default_options()
{
  local menu_title='kunit test inside kw'
  local menu_message_box="This shouldn't be a useful dialog's screen message box"
  local -a menu_list_string_array=('Checklist 1' 'Checklist 2')
  local -a check_statuses=(1 '')
  local expected_cmd="dialog --backtitle \$'${KW_UPSTREAM_TITLE}'"
  local output

  expected_cmd+=" --title $'${menu_title}' --clear --colors --cancel-label $'Exit'"
  expected_cmd+=" --checklist $'This shouldn\'t be a useful dialog\'s screen message box'"
  expected_cmd+=" '${EXPECTED_DEFAULT_HEIGHT}' '${EXPECTED_DEFAULT_WIDTH}' '0'"
  expected_cmd+=" $'Checklist 1' '' 'on' $'Checklist 2' '' 'off'"

  output=$(create_simple_checklist "$menu_title" "$menu_message_box" 'menu_list_string_array' 'check_statuses' '' '' '' '' '' 'TEST_MODE')
  assert_equals_helper 'Expected simple checklist' "$LINENO" "${output}" "${expected_cmd}"
}

function test_create_simple_checklist_use_all_options()
{
  local menu_title='kunit test inside kw'
  local menu_message_box="This shouldn't be a useful dialog's screen message box"
  local -a menu_list_string_array=('Checklist 1' 'Checklist 2')
  local -a check_statuses=(1 '')
  local expected_cmd="dialog --backtitle \$'${KW_UPSTREAM_TITLE}'"
  local output

  expected_cmd+=" --title $'${menu_title}' --clear --colors --cancel-label $'Nop'"
  expected_cmd+=" --extra-button --extra-label 'Return'"
  expected_cmd+=" --checklist $'This shouldn\'t be a useful dialog\'s screen message box'"
  expected_cmd+=" '442' '244' '3'"
  expected_cmd+=" $'Checklist 1' '' 'on' $'Checklist 2' '' 'off'"

  output=$(create_simple_checklist "$menu_title" "$menu_message_box" 'menu_list_string_array' 'check_statuses' 1 'Nop' '442' '244' '3' 'TEST_MODE')
  assert_equals_helper 'Expected simple checklist' "$LINENO" "${output}" "${expected_cmd}"
}

function test_create_loading_screen_notification_rely_on_some_default_options()
{
  local loading_message="kunit's test inside kw"
  local expected_cmd="dialog --colors"
  local output

  expected_cmd+=" --infobox $'kunit\'s test inside kw'"
  expected_cmd+=" '8' '60'"

  output=$(create_loading_screen_notification "$loading_message" '' '' 'TEST_MODE')
  assert_equals_helper 'Expected loading screen with some default options' "$LINENO" "${output}" "${expected_cmd}"
}

function test_create_loading_screen_notification_use_all_options()
{
  local loading_message="kunit's test inside kw"
  local expected_cmd="dialog --colors"
  local output

  expected_cmd+=" --infobox $'kunit\'s test inside kw'"
  expected_cmd+=" '1234' '4321'"

  output=$(create_loading_screen_notification "$loading_message" '1234' '4321' 'TEST_MODE')
  assert_equals_helper 'Expected loading screen with some default options' "$LINENO" "${output}" "${expected_cmd}"
}

function test_create_message_box_rely_on_some_default_options()
{
  local box_title='Bookmarked patches'
  local message_box="There're no bookmarked patches..."
  local expected_cmd=" dialog --backtitle $'${KW_UPSTREAM_TITLE}'"
  local output

  expected_cmd+=" --title $'${box_title}' --clear --colors"
  expected_cmd+=" --msgbox $'There\'re no bookmarked patches...'"
  expected_cmd+=" '15' '40'"
  output=$(create_message_box "${box_title}" "${message_box}" '' '' 'TEST_MODE')
  assert_equals_helper 'Expected message box with some default options' "$LINENO" "$output" "${expected_cmd}"
}

function test_create_message_box_use_all_options()
{
  local box_title='Bookmarked patches'
  local message_box="There're no bookmarked patches..."
  local expected_cmd=" dialog --backtitle $'${KW_UPSTREAM_TITLE}'"
  local output

  expected_cmd+=" --title $'${box_title}' --clear --colors"
  expected_cmd+=" --msgbox $'There\'re no bookmarked patches...'"
  expected_cmd+=" '1234' '4321'"
  output=$(create_message_box "${box_title}" "${message_box}" '1234' '4321' 'TEST_MODE')
  assert_equals_helper 'Expected message box with all custom options' "$LINENO" "$output" "${expected_cmd}"
}

function test_prettify_string_failures()
{
  prettify_string
  assert_equals_helper 'Expected failure' "$LINENO" "$?" 22

  prettify_string 'Something'
  assert_equals_helper 'Expected failure' "$LINENO" "$?" 22
}

function test_prettify_string()
{
  local output
  local expected_string='\Zb\Z6Series:\ZnSomething\n'

  output=$(prettify_string 'Series:' 'Something')
  assert_equals_helper 'Expected pretty string' "$LINENO" "$output" "$expected_string"
}

invoke_shunit
