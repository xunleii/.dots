# Empty on purpose: silences fish's default greeting. Declarative and
# chezmoi-managed, unlike `set -U fish_greeting ''` — a universal variable
# lives in fish_variables, which this repo does not (and should not) manage.
function fish_greeting
end
