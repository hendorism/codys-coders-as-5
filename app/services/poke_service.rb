class PokeService
  include HTTParty

  BASE_URI = "https://pokeapi.co/api/v2/pokemon/"

  def get_pokemon_list(offset, limit)
    response = HTTParty.get(BASE_URI + "?offset=" + offset.to_s + "&limit=" + limit.to_s).to_s

    parsed = JSON.parse(response, {symbolize_names: true})

    next_query = get_query_params(parsed[:next])
    prev_query = get_query_params(parsed[:previous])

    with_ids = parsed[:results].map { |x|
      x[:id] = x[:url].partition("pokemon/").last.partition("/").first
      x[:name] = x[:name].capitalize
    }

    return {
      :prev => prev_query,
      :next => next_query,
      :list => parsed[:result]
    }
  end

  def get_pokemon(id)
    response = HTTParty.get(BASE_URI + id).to_s
    parsed = JSON.parse(response, {symbolize_names: true})

    pokename = parsed[:name].capitalize
    pokenumber = "#%03d" % parsed[:id]

    pokesprite = parsed[:sprite][:other][:"official-artwork"][:front_default]

    poketypes = parsed[:types].map { |v| v[:type][:name].capitalize }
    pokeheight = format_info(parsed[:height], "height")
    pokeweight = format_info(parsed[:weight], "weight")

    pokeabils = format_info_list(parsed[:abilities], :ability, :name)
    pokeitems = format_info_list(parsed[:held_items], :item, :name)

    return {
      :name => pokename,
      :num => pokenumber,
      :sprite => pokesprite,
      :types => poketypes,
      :height => pokeheight,
      :weight => pokeweight,
      :abils => pokeabils,
      :items => pokeitems
    }
  end

  private
    def get_query_params(url)

      trimmed = url.to_s.partition("=").last

      offset = trimmed.to_s.partition("&").first

      limit = trimmed.to_s.partition("=").last

      return {
        :offset => offset,
        :limit => limit
      }
    end

    def format_info(raw, type)
      case types
      when "weight"
        converted = raw / 4.536
        rounded = converted < 1 ? converted.round(1) : converted.round()
        formatted = rounded.to_s.concat(" lbs")
      when "height"
        converted = raw * 3.937
        feet = converted.round() / 12
        inches = converted.round() % 12
        formatted = ""
        unless feet == 0
          formatted.concat("#{feet.to_s}\'")
        end
        unless inches == 0
          formatted.concat("#{inches.to_s}\"")
        end
      end

      return formatted
    end

    def format_info_list(raw, sym1, sym2)
      formatted = raw.map { |v| v[sym1][sym2].sub('-', ' ').capitalize }

      str_from_arr = formatted.empty? ? "None" : formatted.join(', ')

      return str_from_arr
    end
end
