Rails.application.routes.draw do

  root 'pages#home'
  get '/search' => 'pages#search'
  post '/search' => 'pages#search'
  get '/fasta' => 'pages#fasta'
  post '/publications' => 'pages#publications'

end
