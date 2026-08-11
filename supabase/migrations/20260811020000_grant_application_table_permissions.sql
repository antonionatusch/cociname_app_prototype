grant select on table public.subscription_plans to authenticated;

grant select on table public.dish_categories to authenticated;
grant select, insert, update on table public.dish_publications to authenticated;
grant select, insert on table public.dish_photos to authenticated;
grant select on table public.ingredients to authenticated;
grant select on table public.allergens to authenticated;
grant select on table public.ingredient_allergens to authenticated;
grant select, insert on table public.dish_ingredients to authenticated;
grant select, insert on table public.vision_inference_logs to authenticated;

grant select, insert on table public.consumer_requests to authenticated;
grant select, insert on table public.cook_offers to authenticated;
grant select, insert on table public.orders to authenticated;
grant select, insert on table public.order_delivery_photos to authenticated;
