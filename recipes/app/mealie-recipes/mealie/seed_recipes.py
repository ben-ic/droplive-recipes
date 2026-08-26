"""Seed a small, usable recipe collection through Mealie's local API."""

from __future__ import annotations

import json
import os
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


BASE_URL = "http://127.0.0.1:9000"

RECIPES = (
    {
        "@context": "https://schema.org",
        "@type": "Recipe",
        "name": "Northstar Relay Weeknight Pasta",
        "description": "A fast tomato and spinach pasta for a busy release week.",
        "recipeYield": "4 servings",
        "prepTime": "PT10M",
        "cookTime": "PT20M",
        "totalTime": "PT30M",
        "keywords": "weeknight,pasta,team dinner",
        "recipeIngredient": [
            "12 oz pasta", "2 tbsp olive oil", "3 cloves garlic, minced",
            "1 can crushed tomatoes", "4 cups spinach", "1/2 cup grated parmesan",
        ],
        "recipeInstructions": [
            "Cook the pasta in salted water until tender.",
            "Warm olive oil and cook garlic for one minute.",
            "Add tomatoes and simmer for ten minutes.",
            "Fold in spinach, then toss with pasta and parmesan.",
        ],
    },
    {
        "@context": "https://schema.org",
        "@type": "Recipe",
        "name": "Release Day Grain Bowl",
        "description": "A make-ahead lunch bowl with roasted vegetables and lemon dressing.",
        "recipeYield": "4 servings",
        "prepTime": "PT15M",
        "cookTime": "PT25M",
        "totalTime": "PT40M",
        "keywords": "lunch,make ahead,vegetarian",
        "recipeIngredient": [
            "2 cups cooked brown rice", "1 sweet potato, cubed", "1 zucchini, sliced",
            "1 can chickpeas, drained", "2 tbsp olive oil", "1 lemon", "4 tbsp tahini",
        ],
        "recipeInstructions": [
            "Heat the oven to 425 F.",
            "Roast sweet potato, zucchini, and chickpeas with olive oil for 25 minutes.",
            "Whisk tahini, lemon juice, water, and salt into a dressing.",
            "Divide rice and vegetables into bowls. Add the dressing before serving.",
        ],
    },
    {
        "@context": "https://schema.org",
        "@type": "Recipe",
        "name": "Customer Call Breakfast Oats",
        "description": "Overnight oats that are ready before the first customer call.",
        "recipeYield": "2 servings",
        "prepTime": "PT5M",
        "totalTime": "PT8H5M",
        "keywords": "breakfast,overnight,oats",
        "recipeIngredient": [
            "1 cup rolled oats", "1 cup milk", "1/2 cup Greek yogurt",
            "1 tbsp chia seeds", "1 tbsp maple syrup", "1 cup berries",
        ],
        "recipeInstructions": [
            "Stir oats, milk, yogurt, chia seeds, and maple syrup in a jar.",
            "Cover and refrigerate overnight.",
            "Top with berries before serving.",
        ],
    },
    {
        "@context": "https://schema.org", "@type": "Recipe",
        "name": "Monday Planning Sheet-Pan Chicken",
        "description": "A lemon chicken tray bake for a full team planning day.",
        "recipeYield": "4 servings", "prepTime": "PT15M", "cookTime": "PT35M", "totalTime": "PT50M",
        "keywords": "dinner,weeknight,chicken,meal prep",
        "recipeIngredient": ["8 chicken thighs", "1 lb baby potatoes", "2 peppers", "1 lemon", "2 tbsp olive oil", "1 tsp oregano"],
        "recipeInstructions": ["Heat oven to 425 F.", "Toss potatoes and peppers with oil and oregano.", "Add chicken and lemon slices.", "Roast until chicken reaches 165 F, about 35 minutes."],
    },
    {
        "@context": "https://schema.org", "@type": "Recipe",
        "name": "Customer Review Tomato Soup",
        "description": "A simple roasted tomato soup with grilled cheese for an afternoon review.",
        "recipeYield": "4 servings", "prepTime": "PT10M", "cookTime": "PT35M", "totalTime": "PT45M",
        "keywords": "lunch,soup,vegetarian",
        "recipeIngredient": ["2 lb tomatoes", "1 onion", "4 cloves garlic", "3 cups stock", "1/4 cup cream", "basil"],
        "recipeInstructions": ["Roast tomatoes, onion, and garlic at 425 F.", "Blend with warm stock.", "Stir in cream and basil.", "Season and serve hot."],
    },
    {
        "@context": "https://schema.org", "@type": "Recipe",
        "name": "On-Call Ginger Noodle Bowl",
        "description": "A quick noodle bowl for a late support handoff.",
        "recipeYield": "2 servings", "prepTime": "PT10M", "cookTime": "PT15M", "totalTime": "PT25M",
        "keywords": "quick,noodles,vegetarian",
        "recipeIngredient": ["6 oz noodles", "1 tbsp ginger", "2 cloves garlic", "2 cups bok choy", "1 carrot", "2 tbsp soy sauce"],
        "recipeInstructions": ["Cook noodles.", "Sauté ginger, garlic, carrot, and bok choy.", "Add soy sauce and a splash of noodle water.", "Toss with noodles and serve."],
    },
    {
        "@context": "https://schema.org", "@type": "Recipe",
        "name": "Release Gate Salmon and Greens",
        "description": "A 25-minute salmon dinner with greens and rice.",
        "recipeYield": "4 servings", "prepTime": "PT10M", "cookTime": "PT15M", "totalTime": "PT25M",
        "keywords": "dinner,salmon,healthy",
        "recipeIngredient": ["4 salmon fillets", "2 cups rice", "8 oz green beans", "1 lemon", "1 tbsp olive oil", "dill"],
        "recipeInstructions": ["Cook rice.", "Season salmon with lemon and dill.", "Roast salmon and beans at 425 F for 12 minutes.", "Serve over rice."],
    },
    {
        "@context": "https://schema.org", "@type": "Recipe",
        "name": "Friday Retrospective Chocolate Banana Bread",
        "description": "A shareable banana bread for the weekly retrospective.",
        "recipeYield": "1 loaf", "prepTime": "PT15M", "cookTime": "PT55M", "totalTime": "PT70M",
        "keywords": "baking,breakfast,snack",
        "recipeIngredient": ["3 ripe bananas", "1/2 cup butter", "3/4 cup sugar", "2 eggs", "1 1/2 cups flour", "1/2 cup chocolate chips"],
        "recipeInstructions": ["Heat oven to 350 F.", "Mash bananas and mix with butter, sugar, and eggs.", "Fold in flour and chocolate chips.", "Bake in a loaf pan for 55 minutes."],
    },
)


def request(path: str, body: dict | None = None, token: str | None = None, form: bool = False) -> dict:
    data = (urlencode(body).encode() if form else json.dumps(body).encode()) if body is not None else None
    headers = {"Content-Type": "application/x-www-form-urlencoded" if form else "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    with urlopen(Request(f"{BASE_URL}{path}", data=data, headers=headers), timeout=10) as response:
        return json.loads(response.read() or b"{}")


def main() -> None:
    for _ in range(60):
        try:
            request("/api/app/about")
            break
        except (HTTPError, URLError):
            time.sleep(2)
    else:
        raise RuntimeError("Mealie did not become ready for the recipe seed")

    login = request("/api/auth/token", {
        "username": os.environ["MEALIE_BOOTSTRAP_EMAIL"],
        "password": os.environ["MEALIE_BOOTSTRAP_PASSWORD"],
    }, form=True)
    token = login.get("access_token")
    if not token:
        raise RuntimeError("Mealie owner login did not return an access token")

    recipes = request("/api/recipes?page=1&perPage=1", token=token)
    if recipes.get("total", 0):
        print("Mealie recipes already exist; preserving the collection", flush=True)
        return

    for recipe in RECIPES:
        request("/api/recipes/create/html-or-json", {
            "includeTags": True,
            "includeImages": False,
            "data": json.dumps(recipe),
        }, token)
    print(f"Seeded {len(RECIPES)} Mealie recipes", flush=True)


if __name__ == "__main__":
    main()
