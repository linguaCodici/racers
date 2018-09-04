class Racer
  include ActiveModel::Model
  attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs

  def initialize(params={})
    @id=params[:_id].nil? ? params[:id] : params[:_id].to_s
    @number=params[:number].to_i
    @first_name=params[:first_name]
    @last_name=params[:last_name]
    @gender=params[:gender]
    @group=params[:group]
    @secs=params[:secs].to_i
  end

  def persisted?
    Rails.logger.debug {"#{id} and #{last_name} persisted?"}
    !@id.nil?
  end

  def created_at
    nil
  end

  def updated_at
    nil
  end

  #returns a MongoDB client configured to
  #communicate to the default database specified
  #in the config/mongoid.yml file.
  def self.mongo_client
    Mongoid::Clients.default
  end

  #returns the racers MongoDB collection holding the Racer documents.
  def self.collection
    self.mongo_client['racers']
  end

  def self.paginate(params)
    Rails.logger.debug("paginate(#{params})")
    page_number = (params[:page] || 1).to_i
    per_page_number = (params[:per_page] || 30).to_i
    skip = (page_number-1)*per_page_number
    limit = per_page_number
    sort = {:number => 1}

    racers=[]
    all(params, sort, skip, limit).each do |doc|
       racers << Racer.new(doc)
    end
    total= all(params, sort, 0, 1).count

    WillPaginate::Collection.create(page_number, limit, total) do |pager|
      pager.replace(racers)
    end
  end


  def self.all(prototype={}, sort={:number => 1}, skip=0, limit=nil)

    prototype=prototype.symbolize_keys.slice(:_id, :number, :first_name, :last_name,
      :gender, :group, :secs) if !prototype.nil?

    Rails.logger.debug {"getting all racers, prototype=#{prototype},
      sort=#{sort}, offset=#{skip}, limit=#{limit}"}

    result = collection.find(prototype).sort(sort).skip(skip)
    result = result.limit(limit) if !limit.nil?

    return result
  end

  def self.find id
    id = BSON::ObjectId.from_string(id) if collection.find("_id"=>id).count == 0
    result = collection.find("_id"=>id).first
    return result.nil? ? nil : Racer.new(result)
  end

  def save
    result = self.class.collection.insert_one({
      number:@number, first_name:@first_name, last_name:@last_name,
      gender:@gender, group:@group, secs:@secs
      })
    @id=result.inserted_id.to_s
  end

  def update(params)
    @number=params[:number].to_i
    @first_name=params[:first_name]
    @last_name=params[:last_name]
    @gender=params[:gender]
    @group=params[:group]
    @secs=params[:secs].to_i

    params.slice!(:number, :first_name, :last_name, :gender, :group, :secs) if !params.nil?
    self.class.collection
      .find(_id:BSON::ObjectId.from_string(@id))
      .update_one(params)
  end

  def destroy
    self.class.collection
      .find(_id:BSON::ObjectId.from_string(@id))
      .delete_one
  end


end
