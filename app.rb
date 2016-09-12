require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
	@db = SQLite3::Database.new 'log.db'
	@db.results_as_hash = true
end

before do
	# индициализация БД
	init_db
end

configure do
	init_db
	# создает таблицу если таблица не существует
	@db.execute 'create table if not exists Posts
	(
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		title TEXT,
		content TEXT,
		created_date DATE
	)'

	@db.execute 'create table if not exists Comments
	(
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		content TEXT,
		post_id INTEGER,
		created_date DATE
	)'
end

get '/' do
	# выбираем список постов из БД
	@results = @db.execute 'select * from Posts order by id desc'

	erb :index
end

get '/css' do
	erb "CSS Docs is <a href='http://getbootstrap.com/css/' target='_blank'>here</a> and <a href='http://getbootstrap.com/components/' target='_blank'>here</a>. <a href='http://v4-alpha.getbootstrap.com/examples/' target='_blank'>Demo</a>"			
end

get '/new' do
	erb :new
end

post '/new' do
	# получаем переменную и post-запроса
	@title = params[:title]
	@content = params[:content]

	if @title.length <= 0
		@error = 'Напишите заголовок'
		return erb :new
	end

	if @content.length <= 0
		@error = 'Напишите текст'
		return erb :new
	end

	# сохранение в БД
	@db.execute 'insert into Posts 
		(
			title, 
			content,
			created_date
		) 
		values (?, ?, datetime())', [@title, @content]

	# @success = "Опубликована запись #{@title}"
	# перенаправление на главную
	redirect to '/'
end

# вывод информации о записи

get '/post/:post_id' do
	# получаем переменную из url
	post_id = params[:post_id]
	# получаем список записей (одну запись)
	results = @db.execute 'select * from Posts where id = ?', [post_id]
	# выбираем эту запись в переменную @row
	@row = results[0]
	# выбираем комментарии для записи
	@comments = @db.execute 'select * from Comments where post_id = ? order by id', [post_id]
	erb :post
end

post '/post/:post_id' do
	post_id = params[:post_id]
	content = params[:content]

	# сохранение в БД
	@db.execute 'insert into Comments 
		(
			content,
			post_id,
			created_date
		) 
		values (?, ?, datetime())', [content, post_id]

	redirect to('/post/' + post_id)
end
