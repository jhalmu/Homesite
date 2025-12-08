import Sortable from "sortablejs";

/**
 * SortableProjects hook for drag-and-drop project reordering.
 *
 * Usage:
 * <div id="project-list" phx-hook="SortableProjects">
 *   <div data-id="1">Project 1</div>
 *   <div data-id="2">Project 2</div>
 * </div>
 *
 * Requires elements to have data-id attributes.
 * Optional .drag-handle class for specific drag areas.
 */
export const SortableProjects = {
  mounted() {
    this.sortable = new Sortable(this.el, {
      animation: 150,
      ghostClass: "opacity-50",
      dragClass: "shadow-lg",
      handle: ".drag-handle",
      onEnd: () => {
        const ids = [...this.el.children]
          .filter((el) => el.dataset.id)
          .map((el) => el.dataset.id);
        this.pushEvent("reorder_projects", { order: ids });
      },
    });
  },

  destroyed() {
    if (this.sortable) {
      this.sortable.destroy();
    }
  },
};
