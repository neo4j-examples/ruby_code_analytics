Rails.application.routes.draw do
  root 'home#index'

  get '/methods' => 'methods#index'
  get '/methods/:defined_class/:method_id' => 'methods#show', as: 'method'

  get '/objects' => 'objects#index'
  get '/objects/:object_id' => 'objects#show', as: 'object'

  get '/nodes' => 'nodes#index'
  get '/nodes/:id' => 'nodes#show', as: 'node'

  resources :trace_points
end
