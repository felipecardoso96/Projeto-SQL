
					----------- ANÁLISE E OTIMIZAÇÃO DO TRÁFEGO --------
                    
-- Data(hoje): 27/nov/2012

-- 1. Acompanhamento mensal de SESSÕES, PEDIDOS e Conversion Rate (CR) via (geral e Gsearch)
	-- Geral
SELECT * FROM website_sessions;
SELECT * FROM orders;

SELECT
	MONTH(WS.created_at) AS month,
	COUNT(DISTINCT WS.website_session_id) AS sessions,
    COUNT(DISTINCT O.order_id) AS orders,
	COUNT(DISTINCT O.order_id)/COUNT(DISTINCT WS.website_session_id) AS CR
FROM website_sessions AS WS
LEFT JOIN orders AS O
	ON WS.website_session_id = O.website_session_id
WHERE WS.created_at < '2012-11-27'
GROUP BY 
	MONTH(WS.created_at);

	-- Gsearch
SELECT
	MONTH(WS.created_at) AS month,
	COUNT(DISTINCT WS.website_session_id) AS sessions,
    COUNT(DISTINCT O.order_id) as orders,
    COUNT(DISTINCT O.order_id)/COUNT(DISTINCT WS.website_session_id) as CR
FROM website_sessions AS WS
LEFT JOIN orders AS O
	ON WS.website_session_id = O.website_session_id
WHERE WS.created_at < '2012-11-27'
	AND WS.utm_source = 'gsearch'
GROUP BY 1
;




-- 2. Acompanhamento mensal (brand x nonbrand campaigns) 
SELECT * FROM website_sessions;
SELECT * FROM orders;

CREATE TEMPORARY TABLE t1
SELECT
	WS.utm_campaign AS campaign,
	MONTH(WS.created_at) AS month,
	WS.website_session_id,
    O.order_id
FROM website_sessions AS WS
LEFT JOIN orders AS O
	ON WS.website_session_id = O.website_session_id
WHERE WS.created_at < '2012-11-27'
	AND WS.utm_source = 'gsearch'
    AND WS.utm_campaign IN ('brand','nonbrand');

SELECT * FROM t1;

SELECT
	MONTH,
	COUNT(DISTINCT CASE WHEN campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN campaign = 'nonbrand' THEN order_id ELSE NULL END) AS nonbrand_orders,
    COUNT(DISTINCT CASE WHEN campaign = 'brand' THEN website_session_id ELSE NULL END) AS brand_sessions,
    COUNT(DISTINCT CASE WHEN campaign = 'brand' THEN order_id ELSE NULL END) AS brand_orders
FROM t1
GROUP BY MONTH;

	-- ou de maneira mais simples e visualmente atraente:

SELECT
	MONTH,
	campaign,
    COUNT(DISTINCT website_session_id) AS sessions,
	COUNT(DISTINCT order_id) AS orders
FROM t1
GROUP BY
	MONTH, campaign;





-- 3. Acompanhamento mensal de SESSÕES e PEDIDOS, de acordo com DEVICE TYPE (Gsearch/nonbrand)
SELECT * FROM website_sessions;
SELECT * FROM orders;

SELECT
	MONTH(WS.created_at) AS month,
    COUNT(CASE WHEN WS.device_type = 'mobile' THEN WS.website_session_id ELSE NULL END) AS mobile_sessions,
	COUNT(CASE WHEN WS.device_type = 'mobile' THEN O.order_id ELSE NULL END) AS mobile_orders,
    COUNT(CASE WHEN WS.device_type = 'desktop' THEN WS.website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(CASE WHEN WS.device_type = 'desktop' THEN O.order_id ELSE NULL END) AS desktop_orders
FROM website_sessions AS WS
LEFT JOIN orders AS O
	ON WS.website_session_id = O.website_session_id
WHERE WS.created_at < '2012-11-27'
	AND WS.utm_source = 'gsearch'
    AND WS.utm_campaign = 'brand'
GROUP BY 
	MONTH(WS.created_at);
    
	-- outra maneira de visualizar:

SELECT
	MONTH(WS.created_at) AS month,
    WS.device_type,
	COUNT(DISTINCT WS.website_session_id) AS sessions,
    COUNT(DISTINCT O.order_id) AS orders
FROM website_sessions AS WS
LEFT JOIN orders AS O
	ON WS.website_session_id = O.website_session_id
WHERE WS.created_at < '2012-11-27'
	AND WS.utm_source = 'gsearch'
    AND WS.utm_campaign = 'brand'
GROUP BY 
	MONTH(WS.created_at),
    WS.device_type;




-- 4. Acompanhamento mensal para Gsearch em OUTROS canais
SELECT * FROM website_sessions GROUP BY utm_source;
SELECT * FROM orders;

SELECT
	MONTH(WS.created_at) AS month,
	WS.utm_source AS source,
    COUNT(DISTINCT WS.website_session_id) AS sessions,
	COUNT(DISTINCT O.order_id) AS orders
FROM website_sessions AS WS
LEFT JOIN orders AS O
	ON WS.website_session_id = O.website_session_id
WHERE WS.created_at < '2012-11-27'
	AND WS.utm_source IN ('gsearch', 'bsearch', 'socialbook')
GROUP BY 
	MONTH(WS.created_at),
    WS.utm_source;



					----------- AVALIAÇÃO DE DESEMPENHO EM TESTES DE PÁGINAS --------

-- 5.  Acompanhamento SEMANAL do volume de tráfego nas landing pages desde antes do teste (bounce rate)
	-- Período do teste: 1/jun - 31/ago
SELECT * FROM website_sessions;
SELECT * FROM website_pageviews;

	-- PASSO 1: Achar landing page
CREATE TEMPORARY TABLE landing_pg_1
SELECT
    WS.website_session_id,
	MIN(WP.website_pageview_id) AS first_pg,
    WP.pageview_url AS landing_pg,
    WS.created_at
FROM website_sessions AS WS
LEFT JOIN website_pageviews AS WP
	ON WS.website_session_id = WP.website_session_id
WHERE WS.created_at > '2012-06-01'
	AND WS.created_at < '2012-08-31'
    AND WS.utm_source = 'gsearch'
    AND WS.utm_campaign = 'nonbrand'
GROUP BY
	WS.website_session_id; 


	-- PASSO 2: Achar as bounced sessions
SELECT * FROM website_pageviews;
SELECT * FROM landing_pg_1;




CREATE TEMPORARY TABLE bounced_sessions_1
SELECT
	LP.website_session_id AS bounced_session,
    LP.landing_pg,
    COUNT(DISTINCT WP.website_pageview_id) AS pages_viewed
FROM landing_pg_1 AS LP
LEFT JOIN website_pageviews AS WP
	ON LP.website_session_id = WP.website_session_id
GROUP BY LP.website_session_id
HAVING 
	COUNT(DISTINCT WP.website_pageview_id) = 1;


	-- PASSO 3: Comparar session x bounced_session e pivotar tabelas de acordo com a SEMANA
SELECT * FROM landing_pg_1;
SELECT * FROM bounced_sessions_1;

SELECT
    DATE(LP.created_at) AS week_start,
    LP.website_session_id,
    BS.bounced_session,
    CASE WHEN LP.landing_pg = '/home' THEN 1 ELSE NULL END AS home_sessions,
    CASE WHEN LP.landing_pg = '/lander-1' THEN 1 ELSE NULL END AS lander_sessions
FROM landing_pg_1 AS LP
LEFT JOIN bounced_sessions_1 AS BS
	ON BS.bounced_session = LP.website_session_id;

	-- PASSO 4: Contar sessões e calcular bounce_rate 
SELECT
    MIN(DATE(LP.created_at)) AS week_start,
    COUNT(CASE WHEN LP.landing_pg = '/home' THEN 1 ELSE NULL END) AS home_sessions,
    COUNT(CASE WHEN LP.landing_pg = '/lander-1' THEN 1 ELSE NULL END) AS lander_sessions,
    COUNT(DISTINCT BS.bounced_session)/COUNT(DISTINCT LP.website_session_id) AS bounce_rate
FROM landing_pg_1 AS LP
LEFT JOIN bounced_sessions_1 AS BS
	ON BS.bounced_session = LP.website_session_id
GROUP BY WEEK(LP.created_at);






-- 6. Estimar a RECEITA gerada através do teste nas landing pages (Gsearch/nonbrand)
	-- Período do teste: 19/jun - 28/jul
SELECT * FROM website_sessions;
SELECT * FROM website_pageviews;

	-- PASSO 1: Achar a primeira página visualizada
CREATE TEMPORARY TABLE landing_pg_2
SELECT
    WS.website_session_id,
	MIN(WP.website_pageview_id) AS first_pg,
    WP.pageview_url AS landing_pg
FROM website_sessions AS WS
LEFT JOIN website_pageviews AS WP
	ON WS.website_session_id = WP.website_session_id
WHERE WS.created_at > '2012-06-19'
	AND WS.created_at < '2012-07-28'
    AND WS.utm_source = 'gsearch'
    AND WS.utm_campaign = 'nonbrand'
GROUP BY
	WS.website_session_id;


	-- PASSO 2: Achar as bounced sessions
SELECT * FROM website_pageviews;
SELECT * FROM landing_pg_2;

CREATE TEMPORARY TABLE bounced_sessions_2
SELECT
	LP.website_session_id AS bounced_session,
    LP.landing_pg,
    COUNT(DISTINCT WP.website_pageview_id) AS pages_viewed
FROM landing_pg_2 AS LP
LEFT JOIN website_pageviews AS WP
	ON LP.website_session_id = WP.website_session_id
GROUP BY LP.website_session_id
HAVING 
	COUNT(DISTINCT WP.website_pageview_id) = 1;


	-- PASSO 3: Comparar sessions x bounced_sessions
SELECT * FROM landing_pg_2;
SELECT * FROM bounced_sessions_2;

SELECT
	LP.landing_pg,
    LP.website_session_id,
    BS.bounced_session
FROM landing_pg_2 AS LP
LEFT JOIN bounced_sessions_2 AS BS
	ON BS.bounced_session = LP.website_session_id;


	-- PASSO 4: CONTAR e CALCULAR bounce_rate
SELECT
	LP.landing_pg,
    COUNT(DISTINCT LP.website_session_id) AS sessions,
    COUNT(DISTINCT BS.bounced_session) AS bounced_sessions,
    COUNT(DISTINCT BS.bounced_session)/COUNT(DISTINCT LP.website_session_id) AS bounce_rate
FROM landing_pg_2 AS LP
LEFT JOIN bounced_sessions_2 AS BS
	ON BS.bounced_session = LP.website_session_id
GROUP BY LP.landing_pg;


	-- PASSO 5.1: VER O QUANTO LUCRAMOS:
		--  Achar o número de SESSÕES, PEDIDOS e CR pra ambas landing pages
SELECT * FROM orders;
SELECT * FROM landing_pg_2;

SELECT
	LP.landing_pg,
    COUNT(LP.landing_pg) AS sessions,
    COUNT(O.order_id) AS orders,
    COUNT(O.order_id)/COUNT(LP.landing_pg) AS CR
FROM landing_pg_2 AS LP
LEFT JOIN orders AS O
	ON LP.website_session_id = O.website_session_id
GROUP BY LP.landing_pg;
	-- CR_home: 0,0318
	-- CR_lander_1: 0,0406

	-- PASSO 5.2: Achar a última vez que "/home" foi visualizada
SELECT
	MAX(WS.website_session_id) AS last_home_session_id
FROM website_sessions AS WS
LEFT JOIN website_pageviews AS WP
	ON WS.website_session_id = WP.website_session_id
WHERE WS.created_at < '2012-11-27'
    AND WS.utm_source = 'gsearch'
    AND WS.utm_campaign = 'nonbrand'
    AND WP.pageview_url= '/home';
    -- id: 17145
    
	-- PASSO 5.3: Contar o número de SESSÕES na nova landing page desde então
SELECT
	COUNT(website_session_id) AS sessions
FROM website_sessions
WHERE website_session_id > 17145
	AND created_at < '2012-11-27'
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand';
	-- 22972 sessions

	-- PASSO 5.4: Calcular CR x SESSÕES para comparar a diferença entre o número de PEDIDOS
		-- Antiga CR (/home): 0,0318 x 22972 sessions = 730 orders
		-- Nova CR (/lander-1): 0,0406 x 22972 sessions =  932 orders
		-- 202 pedidos a mais!







-- 7. Montar funil de conversão pras duas landing pages até orders
	-- Teste feito: 19/jun - 28/jul
SELECT * FROM website_sessions;
SELECT * FROM website_pageviews;

	-- PASSO 1: Achar paginas
CREATE TEMPORARY TABLE table1
SELECT
	WS.website_session_id,
    WP.pageview_url
FROM website_sessions AS WS
LEFT JOIN website_pageviews AS WP
	ON WS.website_session_id = WP.website_session_id
WHERE
	WS.created_at BETWEEN '2012-06-19' AND '2012-07-28'
    AND WS.utm_source = 'gsearch'
    AND WS.utm_campaign = 'nonbrand';

	-- PASSO 2: Marcar páginas relevantes
SELECT * FROM table1;

SELECT
	website_session_id,
    pageview_url,
	CASE WHEN pageview_url = '/home' THEN 1 ELSE NULL END AS home,
    CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE NULL END AS lander_1,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE NULL END AS products,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE NULL END AS mr_fuzzy,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE NULL END AS cart,
	CASE WHEN pageview_url = '/shipping' THEN 1 ELSE NULL END AS shipping,
	CASE WHEN pageview_url = '/billing' THEN 1 ELSE NULL END AS billing,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE NULL END AS thanks
FROM table1;

	-- PASSO 3: Criar o funil
SELECT * FROM table1;
    
CREATE TEMPORARY TABLE funnels
SELECT
	website_session_id,
    MAX(home) AS home,
    MAX(lander_1) AS lander_1,
    MAX(products) AS to_products,
    MAX(mr_fuzzy) AS to_mr_fuzzy,
    MAX(cart) AS to_cart,
    MAX(shipping) AS to_shipping,
    MAX(billing) AS to_billing,
    MAX(thanks) AS to_thanks
FROM(
    SELECT
	website_session_id,
	CASE WHEN pageview_url = '/home' THEN 1 ELSE NULL END AS home,
    CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE NULL END AS lander_1,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE NULL END AS products,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE NULL END AS mr_fuzzy,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE NULL END AS cart,
	CASE WHEN pageview_url = '/shipping' THEN 1 ELSE NULL END AS shipping,
	CASE WHEN pageview_url = '/billing' THEN 1 ELSE NULL END AS billing,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE NULL END AS thanks
FROM table1) AS flag
GROUP BY 
	website_session_id;
    
	-- PASSO 4: Unir ambas landing pages em uma unica coluna e agrupar por elas
SELECT * FROM table1;
SELECT * FROM funnels;

SELECT
	CASE
		WHEN home = 1 THEN 'home'
        WHEN lander_1 = 1 THEN 'lander_1'
        ELSE 'error'
	END AS landing_pg,
    COUNT(website_session_id) AS sessions,
	COUNT(to_products) AS to_products,
    COUNT(to_mr_fuzzy) AS to_mr_fuzzy,
    COUNT(to_cart) AS to_cart,
    COUNT(to_shipping) AS to_shipping,
    COUNT(to_billing) AS to_billing,
	COUNT(to_thanks) AS to_thanks
FROM funnels
GROUP BY landing_pg;

	-- PASSO 5: Calcular rates
SELECT
	landing_pg,
    to_products/sessions AS landing_products_CR,
    to_mr_fuzzy/to_products AS products_mrfuzzy_CR,
    to_cart/to_mr_fuzzy AS mrfuzzy_cart_CR,
    to_shipping/to_cart AS cart_shiping_CR,
    to_billing/to_shipping AS shipping_billing_CR,
	to_thanks/to_billing AS billing_thanks_CR
FROM (
	SELECT
	CASE
		WHEN home = 1 THEN 'home'
        WHEN lander_1 = 1 THEN 'lander_1'
        ELSE 'error'
	END AS landing_pg,
    COUNT(website_session_id) AS sessions,
	COUNT(to_products) AS to_products,
    COUNT(to_mr_fuzzy) AS to_mr_fuzzy,
    COUNT(to_cart) AS to_cart,
    COUNT(to_shipping) AS to_shipping,
    COUNT(to_billing) AS to_billing,
	COUNT(to_thanks) AS to_thanks
FROM funnels
GROUP BY landing_pg
) as pivot
GROUP BY landing_pg;



-- 8. Quantificar o impacto do billing test ('/billing' x '/billing-2') em termos de receita por billing page session + impacto mensal
-- Teste (10/set - 10/nov)
SELECT * FROM website_pageviews;
SELECT * FROM website_sessions;

	-- PASSO 1: Billing Test - Cruzar PEDIDOS e SESSÕES restringindo somente as páginas relevantes
SELECT
	WP.website_session_id,
    WP.pageview_url,
    order_id
FROM website_pageviews AS WP
LEFT JOIN orders AS O
	ON WP.website_session_id = O.website_session_id
WHERE WP.created_at BETWEEN '2012-09-10' AND '2012-11-10'
	AND WP.pageview_url IN ('/billing', '/billing-2');

	-- PASSO 2: Contar e calcular CR
SELECT 
	pageview_url,
    COUNT(website_session_id) AS sessions,
    COUNT(order_id) as orders,
    COUNT(order_id)/COUNT(website_session_id) AS CR
FROM
(
SELECT
	WP.website_session_id,
    WP.pageview_url,
    order_id
FROM website_pageviews AS WP
LEFT JOIN orders AS O
	ON WP.website_session_id = O.website_session_id
WHERE WP.created_at BETWEEN '2012-09-10' AND '2012-11-10'
	AND WP.pageview_url IN ('/billing', '/billing-2')
) as t1
GROUP BY 1;

	-- PASSO 3: Calcular revenue

SELECT
	billing_version,
    COUNT(website_session_id) AS sessions,
    SUM(price_usd)/COUNT(website_session_id) AS revenue_per_session
FROM
	(SELECT
	WP.website_session_id,
    WP.pageview_url AS billing_version,
    O.order_id,
    O.price_usd
FROM website_pageviews AS WP
LEFT JOIN orders AS O
	ON WP.website_session_id = O.website_session_id
WHERE WP.created_at BETWEEN '2012-09-10' AND '2012-11-10'
	AND pageview_url IN ('/billing', '/billing-2')
    ) as t1
GROUP BY 1;

-- OLD billing: 22,8$ per session
-- NEW billing: 31,3$ per session
-- LIFT: 8,5$ per session

	-- PASSO 4: Calcular LIFT no último mês
SELECT
	COUNT(website_session_id) AS billing_last_month
FROM website_pageviews
WHERE created_at BETWEEN '2012-10-27' AND '2012-11-27'
	AND pageview_url IN ('/billing', '/billing-2');

-- 1193 billing sessions no último mês x LIFT (8,5$ per session) = 10.140$ a mais no último mês

