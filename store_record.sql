CREATE OR REPLACE FUNCTION public.store_record(schema_name text, table_name text, cols text[], ex_cols text[] DEFAULT ARRAY[]::text[], pks text[] DEFAULT ARRAY[]::text[], ret text[] DEFAULT ARRAY[]::text[], flags text[] DEFAULT ARRAY[]::text[])
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare
 qry text='';
begin
    select 'insert into ' || quote_ident(t.table_schema)||'.'||quote_ident(t.table_name) || ' as t('||
           string_agg(quote_ident(c.column_name),',') || ')values(' ||
           -- string_agg(quote_literal(val->>c.column_name),',')||')'
           string_agg('($1->>'||quote_literal(c.column_name)||')::'|| c.data_type,', ')||')'
           
    || case when pks is not null and array_length(pks,1)>0 then
       chr(10)||' on conflict(' || (select string_agg(quote_ident(v),',') from unnest(pks) as u(v))||') do update set '||
       string_agg(quote_ident(c.column_name)||'=excluded.'||quote_ident(c.column_name), ',')filter(where not c.column_name=any(pks))
    ||' where ' || coalesce(string_agg('t.'||quote_ident(c.column_name)||' is distinct from excluded.'||quote_ident(c.column_name), ' or ')filter(where not c.column_name=any(pks)),' true')
    else '' end 
    
    || case when ret is not null and array_length(ret,1)>0 then
      (select chr(10)||' returning jsonb_build_object(' || string_agg(quote_literal(v) || ', t.' || quote_ident(v),', ')||')' from unnest(ret) as u(v))  
    else '' end
    into qry
           from information_schema.tables t 
                                join information_schema.columns c on 
                                        t.table_catalog = c.table_catalog 
                                    and t.table_schema =c.table_schema 
                                    and t.table_name =c.table_name
    where t.table_catalog=current_catalog and t.table_schema=store_record.schema_name and t.table_name=store_record.table_name
    and (c.column_name=any(cols) or cols is null or array_length(cols,1)=0) and c.column_name<>all(coalesce(ex_cols,array[]::text[]))
    group by t.table_catalog, t.table_schema, t.table_name;
    return qry;
end
$function$
;

