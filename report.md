# RESTify Study - Unit Test Report
 * [Blue-Fox](#blue-fox)
 * [Blue-Raccoon](#blue-raccoon)
 * [Blue-Turtle](#blue-turtle)
 * [Blue-Unicorn](#blue-unicorn)
 * [Green-Fox](#green-fox)
 * [Green-Squid](#green-squid)
 * [Green-Turtle](#green-turtle)
 * [Green-Unicorn](#green-unicorn)
 * [Green-Zebra](#green-zebra)
 * [Red-Fox](#red-fox)
 * [Red-Koala](#red-koala)
 * [Red-Raccoon](#red-raccoon)
 * [Red-Squid](#red-squid)
 * [Red-Turtle](#red-turtle)
 * [Red-Unicorn](#red-unicorn)
 * [Yellow-Fox](#yellow-fox)
 * [Yellow-Raccoon](#yellow-raccoon)
 * [Yellow-Turtle](#yellow-turtle)
 * [Yellow-Unicorn](#yellow-unicorn)
 * [Yellow-Zebra](#yellow-zebra)

## Blue-Fox

 * Manual: RUNNABLE, Tests passed:        8/      12
```
[Get]  /bookstore/isbns                                  0.386 sec
[Get]  /bookstore/isbns/isbn                             0.33 sec
[Put]  /bookstore/isbns/isbn                             0.339 sec
[Get]  /bookstore/stocklocations                         0.309 sec
[Get]  /bookstore/stocklocations/stocklocation           0.319 sec
[Get]  /bookstore/stocklocations/stocklocation/isbns     0.32 sec
[Post] /bookstore/stocklocations/stocklocation/isbns     0.326 sec
[Get]  /bookstore/isbns/isbn/comments                    0.33 sec
[Post] /bookstore/isbns/isbn/comments                    0.341 sec <<< FAILURE!
[Del]  /bookstore/isbns/isbn/comments                    0.331 sec <<< FAILURE!
[Post] /bookstore/isbns/isbn/comments/comment            0.328 sec <<< FAILURE!
[Del]  /bookstore/isbns/isbn/comments/comment            0.333 sec <<< FAILURE!
```
 * Manual: MISSING

## Blue-Raccoon

