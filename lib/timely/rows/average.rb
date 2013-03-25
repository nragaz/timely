# encoding: UTF-8

class Timely::Rows::Average < Timely::Row
  self.default_options = { transform: :round }
end