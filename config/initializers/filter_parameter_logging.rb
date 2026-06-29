Rails.application.config.filter_parameters += %i[
  password token id_token authorization email name
]
