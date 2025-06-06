<?php
/**
 * Plugin Name: Hespress Clone API Extended Clean
 * Description: API pour Flutter avec recherche, pagination, catégorie, tags, vues, etc.
 * Version: 1.0
 * Author: Adil Mokhtari
 */

add_action('rest_api_init', function () {
    register_rest_route('myapp/v1', '/posts/', [
        'methods'  => 'GET',
        'callback' => 'get_custom_posts_clean',
    ]);

    register_rest_route('myapp/v1', '/categories/', [
        'methods'  => 'GET',
        'callback' => 'get_custom_categories_with_icons',
    ]);

    register_rest_route('myapp/v1', '/most-viewed/', [
        'methods'  => 'GET',
        'callback' => 'get_most_viewed_posts',
    ]);
});

// ✅ Endpoint /posts (avec search + category fonctionnels)
function get_custom_posts_clean($data) {
    $search      = isset($data['search'])      ? sanitize_text_field($data['search']) : '';
    $page        = isset($data['page'])        ? max(1, intval($data['page']))        : 1;
    $per_page    = isset($data['per_page'])    ? intval($data['per_page'])            : 10;
    $category_id = isset($data['categories'])  ? intval($data['categories'])          : 0;
    $tag_id      = isset($data['tags'])        ? intval($data['tags'])                : 0;

    $args = [
        'post_type'      => 'post',
        'posts_per_page' => $per_page,
        'paged'          => $page,
        's'              => $search,
    ];

    // ✅ tax_query pour éviter conflit entre 'cat' et 's'
    if ($category_id > 0) {
        $args['tax_query'][] = [
            'taxonomy' => 'category',
            'field'    => 'term_id',
            'terms'    => [$category_id],
        ];
    }

    if ($tag_id > 0) {
        $args['tag_id'] = $tag_id;
    }

    $query = new WP_Query($args);
    $posts = [];

    while ($query->have_posts()) {
        $query->the_post();
        $post_id = get_the_ID();
        $categories = get_the_category($post_id);
        $tags = wp_get_post_tags($post_id);
        $views = get_post_meta($post_id, 'post_views_count', true);
        $content = wp_strip_all_tags(apply_filters('the_content', get_the_content()));
        $image = get_the_post_thumbnail_url($post_id, 'full');

        $posts[] = [
            'id'            => (string) $post_id,
            'title'         => (string) get_the_title(),
            'excerpt'       => (string) wp_trim_words(get_the_excerpt(), 30, '...'),
            'content'       => $content,
            'image'         => $image ?: '',
            'date'          => (string) get_the_date(),
            'comment_count' => (int) get_comments_number($post_id),
            'views'         => (int) ($views ?: 0),
            'categories'    => array_map(function ($cat) {
                return [
                    'id'   => (string) $cat->term_id,
                    'name' => (string) $cat->name,
                    'slug' => (string) $cat->slug,
                ];
            }, $categories),
            'tags' => array_map(function ($tag) {
                return [
                    'id'   => (string) $tag->term_id,
                    'name' => (string) $tag->name,
                    'slug' => (string) $tag->slug,
                ];
            }, $tags),
        ];
    }

    wp_reset_postdata();
    return rest_ensure_response($posts);
}

// ✅ Endpoint /categories avec icône facultatif
function get_custom_categories_with_icons() {
    $categories = get_categories();
    $output = [];

    foreach ($categories as $cat) {
        $icon_url = get_term_meta($cat->term_id, 'icon_url', true);
        $output[] = [
            'id'       => (string) $cat->term_id,
            'name'     => (string) $cat->name,
            'slug'     => (string) $cat->slug,
            'icon_url' => $icon_url ?: '',
        ];
    }

    return rest_ensure_response($output);
}

// ✅ Endpoint /most-viewed (top 10)
function get_most_viewed_posts() {
    $args = [
        'post_type'      => 'post',
        'meta_key'       => 'post_views_count',
        'orderby'        => 'meta_value_num',
        'order'          => 'DESC',
        'posts_per_page' => 10,
    ];

    $query = new WP_Query($args);
    $posts = [];

    while ($query->have_posts()) {
        $query->the_post();
        $post_id = get_the_ID();

        $posts[] = [
            'id'            => (string) $post_id,
            'title'         => (string) get_the_title(),
            'content'       => (string) wp_strip_all_tags(get_the_content()),
            'image'         => get_the_post_thumbnail_url($post_id, 'full') ?: '',
            'date'          => (string) get_the_date(),
            'comment_count' => (int) get_comments_number($post_id),
        ];
    }

    wp_reset_postdata();
    return rest_ensure_response($posts);
}

// ✅ Incrément automatique des vues
function flutter_increment_post_views($post_id) {
    if (!is_single() || empty($post_id)) return;

    $key = 'post_views_count';
    $views = get_post_meta($post_id, $key, true);
    $views = $views ? intval($views) + 1 : 1;
    update_post_meta($post_id, $key, $views);
}

add_action('wp_head', function () {
    if (is_single()) {
        global $post;
        if ($post && isset($post->ID)) {
            flutter_increment_post_views($post->ID);
        }
    }
});
