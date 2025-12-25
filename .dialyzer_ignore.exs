# Dialyzer ignore file
# These warnings are false positives from library opaque type handling
[
  # MapSet opaque type mismatch - internal implementation detail of Erlang :sets
  # This is a known Dialyzer issue with OTP 28+ MapSet changes
  {"lib/homesite/external_feeds/opml.ex", :call_without_opaque},

  # Gettext.Plural opaque type - internal library detail
  {"lib/homesite_web/gettext.ex", :call_without_opaque}
]
