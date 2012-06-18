
Stylesheet Workflow and Guidelines
==================================

Inclusion in the application
------------------------------

The only stylesheet included by the application is
`app/assets/stylesheets/application.scss` (as per <em>Rails 3.1</em>
convention). However, no styles should be put directly in this file. Rather,
more specific style files in app/assets/stylesheets should be imported into
application.scss.

Custom stylesheets specific to this project should be placed in
`app/assets/stylesheets/project_specific`.


Project specific
----------------

Inside `app/assets/stylesheets/project_specific`, there is a style definitions
file, _defs.scss, a file of utility mixins and functions, _mixins.scss, and SCSS
classes. SCSS classes are organized into a class file, with the same name as
the class, and a definitions file, with the name of the class appended by _defs.

New SCSS classes can be created by using the scss_class generator (see
the [Generator documentation][]).

  [Generator documentation]: ../file.Generators.html

Because of this extensive use of the css `import` function, reloading CSS
in development mode is slow. As a point of future development, a custom SCSS
importer could be written that works more like the C header #include directive.
That way, files would only be imported once. This would also eliminate the
possibility of cycles (though following the style design guidelines listed
below should prevent the occurence of cycles).


Style Design Guidelines
-----------------------

Style properties that are relevant only to an HTML element's internal state,
such as its size, padding, text color, background-color, and border should be
set in the class file. In contrast, style properties that are relevent outside
of an HTML element, such as its position and margin, should be set in the parent
element's class.

As necessary, class stylesheets may import definition files from other classes,
but they should not import class files.

For variables in the definition files, the convention is that they will be
prefixed with the class name, since there is no way to specify scope in SCSS.

Software design best practices should be followed regarding mixins, functions,
variables, and inheritance (done in SCSS through the `extend` keyword).

SCSS classes may also be created not to be applied directly to HTML elements,
but to be inherted by other SCSS classes. These classes should be placed in
the `abstract` directory in `app/assets/stylesheets/project_specific`.
