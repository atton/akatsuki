def user_informations
  {
    akatsuki: 'Full-fledged-Lady',
    hibiki:   'Phoenix-name-is-not-a-waste',
    ikazuchi: 'It-came-a-letter-to-the-commander',
    inazuma:  'I-never-like-NAS',
    mutsuki:  'Paper-Armor',
    yayoi:    'I-Hate-Bomber',
    kisaragi: 'Thick-Torpedoes',
    satsuki:  'No-you-such-willing-to-fight-me?',  # graduate
  }
end

def user_information_by_type type
  id = {
    student: :akatsuki,
    adjunct: :hibiki,
    teacher: :ikazuchi,
    other:   :inazuma,
  }[type]
  [id, user_informations[id]]
end

def user_information_by_role role
  id = {
    student:             :akatsuki,
    syskan:              :kisaragi,
    iesudoer:            :yayoi,
    iesudoer_and_syskan: :mutsuki,
    graduate:            :satsuki,
  }[role]
  [id, user_informations[id]]
end

def user_sign_in uid, password
  visit sign_in_path
  fill_in :uid,      with: uid
  fill_in :password, with: password
  click_button 'Sign in'
end

def user_sign_in_by_uid uid
  user_sign_in uid, user_informations[uid]
end

def user_sign_in_by_role role
  info = user_information_by_role role
  user_sign_in info.first, info.last
end

def user_sign_in_by_type type
  info = user_information_by_type type
  user_sign_in info.first, info.last
end

