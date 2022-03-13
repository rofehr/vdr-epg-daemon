CREATE VIEW eventsview as select cnt_useid useid, cnt_eventid eventid, cnt_channelid channelid, cnt_source source, all_updsp updsp, cnt_updflg updflg, cnt_delflg delflg, cnt_fileref fileref, cnt_tableid tableid, cnt_version version, sub_title title,
case when sub_shorttext is NULL then
  concat(
    case when length(ifnull(sub_category,'')) > 0 then sub_category else '' end,
    case when length(ifnull(sub_category,'')) > 0 and length(ifnull(sub_genre,'')) > 0 then ' - ' else '' end,
    case when length(ifnull(sub_genre,'')) > 0 then sub_genre else '' end,
    case when length(ifnull(sub_genre,'')) > 0 and length(ifnull(sub_country,'')) + length(ifnull(sub_year,'')) > 0 then ' (' else '' end,
    case when length(ifnull(sub_country,'')) > 0 then sub_country else '' end,
    case when length(ifnull(sub_country,'')) > 0 and length(ifnull(sub_year,'')) > 0 then ' ' else '' end,
    case when length(ifnull(sub_year,'')) > 0 then sub_year else '' end,
    case when length(ifnull(sub_genre,'')) > 0 and length(ifnull(sub_country,'')) + length(ifnull(sub_year,'')) > 0 then ')' else '' end
  )
else
  concat(
    case when length(ifnull(epi_season,'')) > 0 or length(ifnull(epi_part,'')) > 0 then '(' else '' end,
    case when length(ifnull(epi_season,'')) > 0 then concat('S',lpad(format(epi_season,0),2,'0')) else '' end,
    case when length(ifnull(epi_part,'')) > 0 then concat('E', lpad(format(epi_part, 0), 2, '0')) else '' end,
    case when length(ifnull(epi_part,'')) > 0 or length(ifnull(epi_season,'')) > 0 then ') ' else '' end,
    case when length(ifnull(epi_partname,'')) > 0 then epi_partname else sub_shorttext end
  )
end shorttext,
case when sub_longdescription is NULL then
  cnt_longdescription
else
  sub_longdescription
end longdescription,
case when cnt_source <> sub_source then
  concat(upper(replace(cnt_source,'vdr','dvb')),'/',upper(sub_source))
else
  upper(replace(cnt_source,'vdr','dvb'))
end mergesource,
cnt_starttime starttime, cnt_duration duration, cnt_parentalrating parentalrating, cnt_vps vps, cnt_contents contents, replace(
concat(
  TRIM(LEADING '|' FROM
   concat(
    case when sub_shorttext is NULL then '' else
      concat(
        case when length(ifnull(sub_category,'')) > 0 then sub_category else '' end,
        case when length(ifnull(sub_category,'')) > 0 and length(ifnull(sub_genre,'')) > 0 then ' - ' else '' end,
        case when length(ifnull(sub_genre,'')) > 0 then sub_genre else '' end,
        case when length(ifnull(sub_genre,'')) > 0 and length(ifnull(sub_country,'')) + length(ifnull(sub_year,'')) > 0 then ' (' else '' end,
        case when length(ifnull(sub_country,'')) > 0 then sub_country else '' end,
        case when length(ifnull(sub_country,'')) > 0 and length(ifnull(sub_year,'')) > 0 then ' ' else '' end,
        case when length(ifnull(sub_year,'')) > 0 then sub_year else '' end,
        case when length(ifnull(sub_genre,'')) > 0 and length(ifnull(sub_country,'')) + length(ifnull(sub_year,'')) > 0 then ')' else '' end
      )
    end,
    concat('||',
      TRIM(LEADING '|' FROM concat(
        case when sub_shortdescription is NULL then '' else sub_shortdescription end,
        case when sub_shortreview is NULL then '' else concat('|',sub_shortreview) end,
        case when sub_tipp is NULL and sub_txtrating is NULL and sub_rating is NULL then '' else '|' end,
        case when sub_tipp is NULL then '' else concat('|»',upper(sub_tipp),'« ') end,
        case when sub_txtrating is NULL then '' else case when sub_tipp is NULL then concat('|',sub_txtrating) else sub_txtrating end end,
        case when sub_rating is NULL then '' else concat('|',regexp_replace(sub_rating,'^ / ','')) end,
        concat('||',
          TRIM(LEADING '|' FROM concat(
            case when sub_topic is NULL then '' else concat('Thema: ',sub_topic) end,
            case when sub_longdescription is NULL then '' else concat('|',sub_longdescription) end,
            case when sub_moderator is NULL then '' else concat('|','Moderator: ',sub_moderator) end,
            case when sub_commentator is NULL then '' else concat('|','Kommentar: ',sub_commentator) end,
            case when sub_guest is NULL then '' else concat('|','Gäste: ',sub_guest) end,
            case when sub_genre is NULL then '' else concat('||','Genre: ',sub_genre) end,
            case when sub_category is NULL then '' else concat('|','Kategorie: ',sub_category) end,
            case when sub_country is NULL then '' else concat('|','Land: ',sub_country) end,
            case when sub_year is NULL then '' else concat('|','Jahr: ',substring(sub_year,1,4)) end,
            case when cnt_parentalrating is NULL or cnt_parentalrating = 0 then '' else concat('||','FSK: ',cnt_parentalrating) end,
            case when sub_actor is NULL and sub_producer is NULL and sub_other is NULL then '' else '|' end,
            case when sub_actor is NULL then '' else concat('|','Darsteller: ',sub_actor) end,
            case when sub_producer is NULL then '' else concat('|','Produzent: ',sub_producer) end,
            case when sub_other is NULL then '' else concat('|','Sonstige: ',sub_other) end,
            case when sub_director is NULL and sub_screenplay is NULL and sub_camera is NULL and sub_music is NULL and sub_audio is NULL and sub_flags is NULL then '' else '|' end,
            case when sub_director is NULL then '' else concat('|','Regie: ',sub_director) end,
            case when sub_screenplay is NULL then '' else concat('|','Drehbuch: ',sub_screenplay) end,
            case when sub_camera is NULL then '' else concat('|','Kamera: ',sub_camera) end,
            case when sub_music is NULL then '' else concat('|','Musik: ',sub_music) end,
            case when sub_audio is NULL then '' else concat('|','Audio: ',sub_audio) end,
            case when sub_flags is NULL then '' else concat('|','Flags: ',sub_flags) end,
            case when epi_episodename is NULL then '' else concat('||','Serie: ',epi_episodename) end,
            case when epi_shortname is NULL then '' else concat('|','Kurzname: ',epi_shortname) end,
            case when epi_partname is NULL then '' else concat('|','Episode: ',epi_partname) end,
            case when epi_extracol1 is NULL then '' else concat('|',epi_extracol1) end,
            case when epi_extracol2 is NULL then '' else concat('|',epi_extracol2) end,
            case when epi_extracol3 is NULL then '' else concat('|',epi_extracol3) end,
            case when epi_season is NULL then '' else concat('|','Staffel: ',cast(epi_season as char)) end,
            case when epi_part is NULL then '' else concat('|','Staffelfolge: ',cast(epi_part as char)) end,
            case when epi_part is NULL then '' else concat('|','Staffelfolgen: ',cast(epi_parts as char)) end,
            case when epi_number is NULL then '' else concat('|','Folge: ',cast(epi_number as char)) end,
            case when cnt_source <> sub_source then concat('||','Quelle: ',upper(replace(cnt_source,'vdr','dvb')),'/',upper(sub_source)) else concat('||','Quelle: ',upper(replace(cnt_source,'vdr','dvb'))) end
          ))
        )
      ))
    )
   )
  )
)
,'|', '
') as description
from
 useevents;
